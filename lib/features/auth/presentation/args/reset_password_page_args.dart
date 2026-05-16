class ResetPasswordPageArgs {
  final String setupToken;
  final bool isSetPassword;

  const ResetPasswordPageArgs({
    required this.setupToken,
    this.isSetPassword = false,
  });
}
