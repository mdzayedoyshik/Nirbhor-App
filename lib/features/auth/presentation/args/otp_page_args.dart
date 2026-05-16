import '../../../../core/enums/auth_enums.dart';

class OtpPageArgs {
  final String otpVerificationToken;
  final String email;
  // null = forgot-password flow; non-null = registration flow
  final AuthHint? hint;

  const OtpPageArgs({
    required this.otpVerificationToken,
    required this.email,
    this.hint,
  });
}
