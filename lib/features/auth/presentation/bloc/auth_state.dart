part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  final AuthLoadingSource source;
  const AuthLoading(this.source);
  @override
  List<Object?> get props => [source];
}

// email check → password required
class AuthPasswordRequired extends AuthState {
  final String email;
  const AuthPasswordRequired(this.email);
  @override
  List<Object?> get props => [email];
}

// email check → OTP sent (new user or google_no_password)
class AuthOtpSent extends AuthState {
  final String email;
  final AuthHint hint;
  final String otpVerificationToken;

  const AuthOtpSent({
    required this.email,
    required this.hint,
    required this.otpVerificationToken,
  });

  @override
  List<Object?> get props => [email, hint, otpVerificationToken];
}

// forgot-password → OTP sent
class AuthForgotPasswordOtpSent extends AuthState {
  final String email;
  final String otpVerificationToken;

  const AuthForgotPasswordOtpSent({
    required this.email,
    required this.otpVerificationToken,
  });

  @override
  List<Object?> get props => [email, otpVerificationToken];
}

// OTP verified → ready to complete registration
class AuthSetupReady extends AuthState {
  final String setupToken;
  final String email;

  const AuthSetupReady({required this.setupToken, required this.email});

  @override
  List<Object?> get props => [setupToken, email];
}

// OTP verified → ready to set password (google_no_password flow)
class AuthSetPasswordReady extends AuthState {
  final String setupToken;
  const AuthSetPasswordReady(this.setupToken);
  @override
  List<Object?> get props => [setupToken];
}

// OTP verified → ready to reset password (forgot-password flow)
class AuthPasswordResetReady extends AuthState {
  final String setupToken;
  const AuthPasswordResetReady(this.setupToken);
  @override
  List<Object?> get props => [setupToken];
}

// Authenticated
class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

// Password reset success (no auto-login, go back to login)
class AuthPasswordResetSuccess extends AuthState {
  const AuthPasswordResetSuccess();
}

// Unauthenticated (after logout or session check fails)
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}
