import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/enums/auth_enums.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/device_token_service.dart';
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
import '../../domain/usecases/send_device_token_usecase.dart';
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
  final SendDeviceTokenUseCase _sendDeviceToken;
  final DeviceTokenService _deviceTokenService;
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
    required SendDeviceTokenUseCase sendDeviceToken,
    required DeviceTokenService deviceTokenService,
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
        _sendDeviceToken = sendDeviceToken,
        _deviceTokenService = deviceTokenService,
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
    on<AuthDeviceTokenRefreshed>(_onDeviceTokenRefreshed);

    // Sync device token whenever FCM rotates it
    _deviceTokenService.onTokenRefresh.listen((token) {
      add(AuthDeviceTokenRefreshed(token));
    });
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
      await _syncDeviceToken();
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
        emit(AuthPasswordResetReady(result.setupToken));
      } else if (event.hint == AuthHint.newUser) {
        emit(AuthSetupReady(
          setupToken: result.setupToken,
          email: event.email ?? '',
        ));
      } else {
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
      final result = await _login(email: event.email, password: event.password);
      emit(AuthAuthenticated(result.user));
      await _syncDeviceToken();
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
      );
      emit(AuthAuthenticated(result.user));
      await _syncDeviceToken();
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
        await _syncDeviceToken();
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
      final account = await GoogleSignIn.instance.authenticate();
      log('Google Sign-In successful: ${account.email}');
      final idToken = account.authentication.idToken;
      log('Google ID Token: $idToken');
      if (idToken == null) {
        emit(const AuthFailure('Failed to get Google ID token.'));
        return;
      }
      final result = await _googleAuth(idToken: idToken);
      log('Backend authentication successful: ${result.user.email}');
      emit(AuthAuthenticated(result.user));
      await _syncDeviceToken();
    } on GoogleSignInException catch (e, stackTrace) {
      log('Google Sign-In failed: $e', stackTrace: stackTrace);
      if (e.code == GoogleSignInExceptionCode.canceled) {
        emit(const AuthInitial());
      } else {
        emit(AuthFailure(e.description ?? 'Google Sign-In failed. Please try again.'));
      }
    } on PlatformException catch (e, stackTrace) {
      log('Platform exception occurred: $e', stackTrace: stackTrace);
      if (e.code == 'sign_in_canceled') {
        emit(const AuthInitial());
      } else {
        emit(AuthFailure(_message(e)));
      }
    } catch (e, stackTrace) {
      log('Unexpected error occurred: $e', stackTrace: stackTrace);
      emit(AuthFailure(_message(e)));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthLoadingSource.logout));
    try {
      final token = await _deviceTokenService.getToken() ?? '';
      await _logout(token);
    } catch (_) {
      await _tokenService.clearTokens();
    }
    emit(const AuthUnauthenticated());
  }

  Future<void> _onDeviceTokenRefreshed(
    AuthDeviceTokenRefreshed event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) return;
    try {
      await _sendDeviceToken(
        token: event.token,
        deviceType: _deviceTokenService.deviceType,
      );
    } catch (_) {}
  }

  // Gets the FCM token and sends it to the backend. Failures are silently
  // ignored — device token registration is non-critical.
  Future<void> _syncDeviceToken() async {
    try {
      final token = await _deviceTokenService.getToken();
      if (token == null) return;
      await _sendDeviceToken(
        token: token,
        deviceType: _deviceTokenService.deviceType,
      );
    } catch (_) {}
  }

  String _message(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    if (e is TokenExpiredException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
