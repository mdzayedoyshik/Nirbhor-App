import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/env/app_env.dart';
import '../../../../core/enums/auth_enums.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/token_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/check_email_usecase.dart';
import '../../domain/usecases/complete_setup_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/google_auth_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CheckEmailUseCase _checkEmail;
  final VerifyOtpUseCase _verifyOtp;
  final LoginUseCase _login;
  final CompleteSetupUseCase _completeSetup;
  final ForgotPasswordUseCase _forgotPassword;
  final ResetPasswordUseCase _resetPassword;
  final GoogleAuthUseCase _googleAuth;
  final LogoutUseCase _logout;
  final GetProfileUseCase _getProfile;
  final TokenService _tokenService;

  AuthBloc({
    required CheckEmailUseCase checkEmail,
    required VerifyOtpUseCase verifyOtp,
    required LoginUseCase login,
    required CompleteSetupUseCase completeSetup,
    required ForgotPasswordUseCase forgotPassword,
    required ResetPasswordUseCase resetPassword,
    required GoogleAuthUseCase googleAuth,
    required LogoutUseCase logout,
    required GetProfileUseCase getProfile,
    required TokenService tokenService,
  })  : _checkEmail = checkEmail,
        _verifyOtp = verifyOtp,
        _login = login,
        _completeSetup = completeSetup,
        _forgotPassword = forgotPassword,
        _resetPassword = resetPassword,
        _googleAuth = googleAuth,
        _logout = logout,
        _getProfile = getProfile,
        _tokenService = tokenService,
        super(const AuthInitial()) {
    on<AuthSessionCheckRequested>(_onSessionCheck);
    on<AuthEmailCheckRequested>(_onEmailCheck);
    on<AuthOtpSubmitted>(_onOtpSubmitted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthCompleteSetupRequested>(_onCompleteSetup);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthResetPasswordRequested>(_onResetPassword);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onSessionCheck(
    AuthSessionCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthLoadingSource.session));
    final hasSession = await _tokenService.hasStoredSession();
    if (!hasSession) {
      emit(const AuthUnauthenticated());
      return;
    }
    try {
      final user = await _getProfile();
      emit(AuthAuthenticated(user));
    } catch (_) {
      await _tokenService.clearTokens();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onEmailCheck(
    AuthEmailCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthLoadingSource.emailCheck));
    try {
      final result = await _checkEmail(event.email);
      if (result.status == AuthCheckStatus.passwordRequired) {
        emit(AuthPasswordRequired(event.email));
      } else {
        emit(AuthOtpSent(
          email: event.email,
          hint: result.hint,
          otpVerificationToken: result.otpVerificationToken!,
        ));
      }
    } catch (e) {
      emit(AuthFailure(_message(e)));
    }
  }

  Future<void> _onOtpSubmitted(
    AuthOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthLoadingSource.otp));
    try {
      final result = await _verifyOtp(
        otpVerificationToken: event.otpVerificationToken,
        otp: event.otp,
      );

      if (event.hint == null) {
        // forgot-password flow
        emit(AuthPasswordResetReady(result.setupToken));
      } else if (event.hint == AuthHint.newUser) {
        emit(AuthSetupReady(
          setupToken: result.setupToken,
          email: event.email ?? '',
        ));
      } else {
        // google_no_password
        emit(AuthSetPasswordReady(result.setupToken));
      }
    } catch (e) {
      emit(AuthFailure(_message(e)));
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthLoadingSource.login));
    try {
      final result = await _login(
        email: event.email,
        password: event.password,
        deviceToken: event.deviceToken,
        deviceType: event.deviceType,
      );
      emit(AuthAuthenticated(result.user));
    } catch (e) {
      emit(AuthFailure(_message(e)));
    }
  }

  Future<void> _onCompleteSetup(
    AuthCompleteSetupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthLoadingSource.completeSetup));
    try {
      final result = await _completeSetup(
        setupToken: event.setupToken,
        name: event.name,
        password: event.password,
        deviceToken: event.deviceToken,
        deviceType: event.deviceType,
      );
      emit(AuthAuthenticated(result.user));
    } catch (e) {
      emit(AuthFailure(_message(e)));
    }
  }

  Future<void> _onForgotPassword(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthLoadingSource.forgotPassword));
    try {
      final otpToken = await _forgotPassword(event.email);
      emit(AuthForgotPasswordOtpSent(
        email: event.email,
        otpVerificationToken: otpToken,
      ));
    } catch (e) {
      emit(AuthFailure(_message(e)));
    }
  }

  Future<void> _onResetPassword(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthLoadingSource.resetPassword));
    try {
      final result = await _resetPassword(
        setupToken: event.setupToken,
        newPassword: event.newPassword,
      );
      if (result.isAutoLogin) {
        final user = await _getProfile();
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthPasswordResetSuccess());
      }
    } catch (e) {
      emit(AuthFailure(_message(e)));
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthLoadingSource.google));
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: AppEnv.googleClientId,
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        emit(const AuthInitial());
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        emit(const AuthFailure('Failed to get Google ID token.'));
        return;
      }
      final result = await _googleAuth(
        idToken: idToken,
        deviceToken: event.deviceToken,
        deviceType: event.deviceType,
      );
      emit(AuthAuthenticated(result.user));
    } catch (e) {
      emit(AuthFailure(_message(e)));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthLoadingSource.logout));
    try {
      await _logout(event.deviceToken);
    } catch (_) {
      // Clear tokens locally even if server call fails
      await _tokenService.clearTokens();
    }
    emit(const AuthUnauthenticated());
  }

  String _message(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    if (e is TokenExpiredException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
