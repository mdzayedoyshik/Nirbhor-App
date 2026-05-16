part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthEmailCheckRequested extends AuthEvent {
  final String email;
  const AuthEmailCheckRequested(this.email);
  @override
  List<Object?> get props => [email];
}

// hint=null means forgot-password flow; non-null means registration flow
class AuthOtpSubmitted extends AuthEvent {
  final String otpVerificationToken;
  final String otp;
  final AuthHint? hint;
  final String? email;

  const AuthOtpSubmitted({
    required this.otpVerificationToken,
    required this.otp,
    this.hint,
    this.email,
  });

  @override
  List<Object?> get props => [otpVerificationToken, otp, hint, email];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthCompleteSetupRequested extends AuthEvent {
  final String setupToken;
  final String name;
  final String password;

  const AuthCompleteSetupRequested({
    required this.setupToken,
    required this.name,
    required this.password,
  });

  @override
  List<Object?> get props => [setupToken, name, password];
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;
  const AuthForgotPasswordRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class AuthResetPasswordRequested extends AuthEvent {
  final String setupToken;
  final String newPassword;

  const AuthResetPasswordRequested({
    required this.setupToken,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [setupToken, newPassword];
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

// Fired internally when FCM refreshes the push token
class AuthDeviceTokenRefreshed extends AuthEvent {
  final String token;
  const AuthDeviceTokenRefreshed(this.token);
  @override
  List<Object?> get props => [token];
}

// Triggered on app start to check for a stored session
class AuthSessionCheckRequested extends AuthEvent {
  const AuthSessionCheckRequested();
}
