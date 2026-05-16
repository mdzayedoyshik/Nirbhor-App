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
  static const String deviceToken = '/auth/device-token';
  static const String upload = '/upload';

  // Flat
  static const String flats = '/flats';
  static const String flatsMine = '/flats/mine';
  static String flat(String id) => '/flats/$id';
  static const String flatsMyRequests = '/flats/my-requests';
  static String flatsJoinPreview(String code) => '/flats/join/$code';
  static const String flatsJoin = '/flats/join';
  static String flatsJoinRequest(String requestId) =>
      '/flats/join/requests/$requestId';
  static String flatJoinRequests(String flatId) =>
      '/flats/$flatId/join-requests';
  static String flatJoinRequestApprove(String flatId, String requestId) =>
      '/flats/$flatId/join-requests/$requestId/approve';
  static String flatJoinRequestDecline(String flatId, String requestId) =>
      '/flats/$flatId/join-requests/$requestId/decline';
  static String flatFixedExpenses(String flatId) =>
      '/flats/$flatId/fixed-expenses';
  static String flatFixedExpense(String flatId, String expenseId) =>
      '/flats/$flatId/fixed-expenses/$expenseId';
  static String flatRedistribute(String flatId) =>
      '/flats/$flatId/redistribute';
  static String flatContributions(String flatId) =>
      '/flats/$flatId/contributions';
}
