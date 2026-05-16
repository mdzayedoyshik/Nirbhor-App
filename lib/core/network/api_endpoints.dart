class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String checkEmail = '/auth/email';
  static const String verifyOtp = '/auth/verify-otp';
  static const String login = '/auth/login';
  static const String completeSetup = '/auth/complete-setup';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String googleAuth = '/auth/google';
  static const String refresh = '/auth/refresh';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';
  static const String logout = '/auth/logout';
}
