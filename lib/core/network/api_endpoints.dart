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

  // Wallet
  static String flatWalletMe(String flatId) => '/flats/$flatId/wallet/me';
  static String flatWallets(String flatId) => '/flats/$flatId/wallets';
  static String flatWalletFlat(String flatId) => '/flats/$flatId/flat-wallet';
  static String flatWalletSummary(String flatId) =>
      '/flats/$flatId/wallet/summary';
  static String flatPaymentRequests(String flatId) =>
      '/flats/$flatId/payment-requests';
  static String flatPaymentRequest(String flatId, String requestId) =>
      '/flats/$flatId/payment-requests/$requestId';
  static String flatPayments(String flatId) => '/flats/$flatId/payments';
  static String flatPaymentVerify(String flatId, String paymentId) =>
      '/flats/$flatId/payments/$paymentId/verify';
  static String flatPaymentReject(String flatId, String paymentId) =>
      '/flats/$flatId/payments/$paymentId/reject';
  static String flatTransactions(String flatId) =>
      '/flats/$flatId/transactions';
  static String flatPaymentHints(String flatId) =>
      '/flats/$flatId/payment-hints';

  // Expense
  static String flatExpenses(String flatId) => '/flats/$flatId/expenses';
  static String flatExpensesSummary(String flatId) =>
      '/flats/$flatId/expenses/summary';
  static String flatExpense(String flatId, String expenseId) =>
      '/flats/$flatId/expenses/$expenseId';
  static String flatExpenseApprove(String flatId, String expenseId) =>
      '/flats/$flatId/expenses/$expenseId/approve';

  // Meal
  static String mealConfig(String flatId) => '/flats/$flatId/meal-config';
  static String mealToggles(String flatId) => '/flats/$flatId/meal-toggles';
  static String mealLogs(String flatId) => '/flats/$flatId/meal-logs';
  static String myMealLog(String flatId) => '/flats/$flatId/meal-logs/me';
  static String mealLogForMember(String flatId, String memberId) =>
      '/flats/$flatId/meal-logs/$memberId';
  static String mealPool(String flatId) => '/flats/$flatId/meal-pool';
  static String mealPreferences(String flatId, String memberId) =>
      '/flats/$flatId/members/$memberId/meal-preferences';
  static String memberMealLogs(String flatId, String memberId) =>
      '/flats/$flatId/members/$memberId/meal-logs';

  // Member
  static String flatMembers(String flatId) => '/flats/$flatId/members';
  static String flatMemberRole(String flatId, String memberId) =>
      '/flats/$flatId/members/$memberId/role';
  static String flatTransferManager(String flatId) =>
      '/flats/$flatId/transfer-manager';
  static String flatMemberInitiateExit(String flatId, String memberId) =>
      '/flats/$flatId/members/$memberId/initiate-exit';
  static String flatMemberSettlement(String flatId, String memberId) =>
      '/flats/$flatId/members/$memberId/settlement';
  static String flatMemberFinalizeExit(String flatId, String memberId) =>
      '/flats/$flatId/members/$memberId/finalize-exit';
  static String flatMemberExit(String flatId, String memberId) =>
      '/flats/$flatId/members/$memberId/exit';

  // Member exit status (self)
  static String meExitStatus() => '/flats/me/exit-status';
  static String meAcknowledgeExit() => '/flats/me/acknowledge-exit';
  static String flatMemberPendingExits(String flatId) =>
      '/flats/$flatId/members/pending-exits';
}
