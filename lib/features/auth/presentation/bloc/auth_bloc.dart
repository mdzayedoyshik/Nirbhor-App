import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/cache/cache_service.dart';
import '../../../../core/enums/auth_enums.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/analytics_properties_manager.dart';
import '../../../../core/services/analytics_service.dart';
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
  final AnalyticsService _analytics;
  final AnalyticsPropertiesManager _propertiesManager;
  final CacheService _cache;

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
    required AnalyticsService analytics,
    required AnalyticsPropertiesManager propertiesManager,
    required CacheService cache,
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
        _analytics = analytics,
        _propertiesManager = propertiesManager,
        _cache = cache,
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
      // Re-identify the user on every session restore so Analytics always
      // has a userId and correct properties, not just on explicit login.
      try {
        await _analytics.setUserId(user.id);
        final createdAt = DateTime.tryParse(user.createdAt);
        final daysOld = createdAt == null ? 0 : DateTime.now().difference(createdAt).inDays;
        await _propertiesManager.setAuthProperties(
          userType: 'member',
          isNewUser: daysOld <= 1,
          apartmentCount: 0,
          isManager: false,
          isPremium: false,
        );
      } catch (_) {}
    } on NetworkException catch (_) {
      // Offline and nothing cached to restore from yet. Keep the session intact
      // (do NOT clear tokens) so a reconnect / relaunch restores it — surfacing
      // the login screen instead of freezing forever on the splash.
      emit(const AuthUnauthenticated());
    } catch (e, stackTrace) {
      // Genuine auth failure (expired / invalid session) — sign out cleanly.
      _analytics.recordException(e, stackTrace, reason: 'AuthBloc._onSessionCheck');
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
        // New user entering the registration funnel
        if (result.hint == AuthHint.newUser) {
          try { await _analytics.logSignupStarted(); } catch (_) {}
        }
        emit(AuthOtpSent(
          email: event.email,
          hint: result.hint,
          otpVerificationToken: result.otpVerificationToken!,
        ));
      }
    } catch (e, stackTrace) {
      _analytics.recordException(e, stackTrace, reason: 'AuthBloc._onEmailCheck');
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
    } catch (e, stackTrace) {
      _analytics.recordException(e, stackTrace, reason: 'AuthBloc._onOtpSubmitted');
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
      // Analytics: log login and set user id/properties
      try {
        await _analytics.logLoginCompleted(loginMethod: 'email');
        await _analytics.setUserId(result.user.id);
        final createdAt = DateTime.tryParse(result.user.createdAt);
        final daysOld = createdAt == null ? 0 : DateTime.now().difference(createdAt).inDays;
        await _propertiesManager.setAuthProperties(
          userType: 'member',
          isNewUser: daysOld <= 1,
          apartmentCount: 0,
          isManager: false,
          isPremium: false,
        );
      } catch (_) {}
    } catch (e, stackTrace) {
      _analytics.recordException(e, stackTrace, reason: 'AuthBloc._onLogin');
      try { await _analytics.logLoginFailed(errorCode: e.runtimeType.toString()); } catch (_) {}
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
      // Analytics: signup completed
      try {
        await _analytics.logSignupCompleted(signupMethod: 'email');
        await _analytics.setUserId(result.user.id);
        final createdAt = DateTime.tryParse(result.user.createdAt);
        final daysOld = createdAt == null ? 0 : DateTime.now().difference(createdAt).inDays;
        await _propertiesManager.setAuthProperties(
          userType: 'member',
          isNewUser: daysOld <= 1,
          apartmentCount: 0,
          isManager: false,
          isPremium: false,
        );
      } catch (_) {}
    } catch (e, stackTrace) {
      _analytics.recordException(e, stackTrace, reason: 'AuthBloc._onCompleteSetup');
      try { await _analytics.logSignupFailed(errorCode: e.runtimeType.toString(), step: 'setup'); } catch (_) {}
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
    } catch (e, stackTrace) {
      _analytics.recordException(e, stackTrace, reason: 'AuthBloc._onForgotPassword');
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
        try { await _analytics.setUserId(user.id); } catch (_) {}
      } else {
        emit(const AuthPasswordResetSuccess());
      }
    } catch (e, stackTrace) {
      _analytics.recordException(e, stackTrace, reason: 'AuthBloc._onResetPassword');
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
      // Analytics: google login
      try {
        await _analytics.logLoginCompleted(loginMethod: 'google');
        await _analytics.setUserId(result.user.id);
        final createdAt = DateTime.tryParse(result.user.createdAt);
        final daysOld = createdAt == null ? 0 : DateTime.now().difference(createdAt).inDays;
        await _propertiesManager.setAuthProperties(
          userType: 'member',
          isNewUser: daysOld <= 1,
          apartmentCount: 0,
          isManager: false,
          isPremium: false,
        );
      } catch (_) {}
    } on GoogleSignInException catch (e, stackTrace) {
      log('Google Sign-In failed: $e', stackTrace: stackTrace);
      if (e.code == GoogleSignInExceptionCode.canceled) {
        emit(const AuthUnauthenticated());
      } else {
        _analytics.recordException(e, stackTrace, reason: 'AuthBloc._onGoogleSignIn: GoogleSignInException');
        try { await _analytics.logLoginFailed(errorCode: e.code.toString()); } catch (_) {}
        emit(AuthFailure(e.description ?? 'Google Sign-In failed. Please try again.'));
      }
    } on PlatformException catch (e, stackTrace) {
      log('Platform exception occurred: $e', stackTrace: stackTrace);
      if (e.code == 'sign_in_canceled') {
        emit(const AuthUnauthenticated());
      } else {
        _analytics.recordException(e, stackTrace, reason: 'AuthBloc._onGoogleSignIn: PlatformException');
        emit(AuthFailure(_message(e)));
      }
    } catch (e, stackTrace) {
      log('Unexpected error occurred: $e', stackTrace: stackTrace);
      _analytics.recordException(e, stackTrace, reason: 'AuthBloc._onGoogleSignIn: unexpected error');
      try { await _analytics.logLoginFailed(errorCode: e.runtimeType.toString()); } catch (_) {}
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
    // Analytics: clear user id and properties
    try {
      await _analytics.logEvent(eventName: 'auth_logout');
      await _analytics.clearUserId();
      await _propertiesManager.clearUserProperties();
    } catch (_) {}
    // Clear cached API responses so the next user never sees stale data.
    try {
      await _cache.clearAll();
    } catch (_) {}
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
