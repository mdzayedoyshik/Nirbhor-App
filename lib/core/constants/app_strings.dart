class AppStrings {
  AppStrings._();

  // General
  static const String appName = 'Nirbhor';
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String close = 'Close';
  static const String loading = 'Loading...';
  static const String retry = 'Retry';
  static const String somethingWentWrong =
      'Something went wrong. Please try again.';
  static const String networkError = 'Network error. Check your connection.';
  static const String offlineBanner = 'No internet · showing saved data';
  static const String offlineAction = "You're offline — reconnect to do that";

  // Email screen
  static const String welcomeTitle = 'Welcome';
  static const String emailSubtitle = 'Enter your email to continue';
  static const String emailLabel = 'Email address';
  static const String emailHint = 'you@example.com';
  static const String continueLabel = 'Continue';

  // OTP screen
  static const String verifyEmailTitle = 'Verify Email';
  static const String otpSentPrefix = "We sent a 6-digit code to\n";
  static const String verifyLabel = 'Verify';
  static const String resendCode = 'Resend code';
  static const String didntReceiveCode = "Didn't receive the code? ";

  // Login screen
  static const String loginTitle = 'Enter Password';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Your password';
  static const String loginLabel = 'Log In';
  static const String forgotPassword = 'Forgot password?';

  // Complete setup
  static const String createAccountTitle = 'Create Account';
  static const String nameLabel = 'Full name';
  static const String nameHint = 'John Doe';
  static const String createPasswordLabel = 'Create password';
  static const String createAccountLabel = 'Create Account';

  // Forgot password
  static const String forgotPasswordTitle = 'Forgot Password';
  static const String forgotPasswordSubtitle =
      'Enter your email to receive a reset code';
  static const String sendResetCode = 'Send Reset Code';

  // Reset password
  static const String resetPasswordTitle = 'Reset Password';
  static const String setPasswordTitle = 'Set Password';
  static const String newPasswordLabel = 'New password';
  static const String newPasswordHint = 'Min. 6 characters';
  static const String resetPasswordLabel = 'Reset Password';

  // Google
  static const String continueWithGoogle = 'Continue with Google';
  static const String orDivider = 'or';

  // Profile
  static const String profileTitle = 'Profile';
  static const String editProfileTitle = 'Edit Profile';
  static const String changePasswordTitle = 'Change Password';
  static const String logoutLabel = 'Log out';
  static const String saveChanges = 'Save Changes';
  static const String oldPasswordLabel = 'Current password';
  static const String confirmLogoutTitle = 'Log out?';
  static const String confirmLogoutMessage =
      'Are you sure you want to log out?';

  // Home
  static const String homeTitle = 'Home';

  // Flat — landing
  static const String noFlatTitle = 'No Flat Yet';
  static const String noFlatSubtitle =
      'Create a new flat or join an existing one.';
  static const String createFlatLabel = 'Create Flat';
  static const String joinFlatLabel = 'Join a Flat';

  // Flat — create
  static const String createFlatTitle = 'Create Flat';
  static const String flatNameLabel = 'Flat name';
  static const String flatNameHint = 'e.g. Mirpur Mess';
  static const String flatAddressLabel = 'Address (optional)';
  static const String flatAddressHint = 'House 12, Road 5';
  static const String flatPhotoUrlLabel = 'Photo URL (optional)';
  static const String flatPhotoUrlHint = 'https://example.com/photo.jpg';
  static const String flatCreatedSuccess = 'Flat created successfully!';
  static const String flatTimezoneLabel = 'Timezone';
  static const String flatTimezonePickerTitle = 'Select Timezone';
  static const String flatTimezoneSearchHint = 'Search timezones...';

  // Flat — join
  static const String joinFlatTitle = 'Join a Flat';
  static const String enterCodeTab = 'Enter Code';
  static const String scanQrTab = 'Scan QR';
  static const String joinCodeLabel = 'Join code';
  static const String joinCodeHint = '6-character code';
  static const String previewFlatLabel = 'Preview Flat';
  static const String joinRequestSentMsg =
      'Join request sent! Waiting for manager approval.';
  static const String sendJoinRequestLabel = 'Send Join Request';
  static const String requestPending = 'Request Pending';
  static const String alreadyMember = 'Already a Member';
  static const String scanQrPrompt = 'Point camera at the flat\'s QR code';

  // Flat — pending request
  static const String pendingRequestTitle = 'Request Pending';
  static const String pendingRequestSubtitle =
      'Your join request is awaiting manager approval.';
  static const String cancelRequestLabel = 'Cancel Request';
  static const String cancelRequestConfirmTitle = 'Cancel Request?';
  static const String cancelRequestConfirmMsg =
      'This will withdraw your join request.';
  static const String requestCancelledMsg = 'Join request cancelled.';

  // Flat — home
  static const String membersSection = 'Members';
  static const String expensesSection = 'Fixed Expenses';
  static const String viewAll = 'View All';
  static const String manageLabel = 'Manage';
  static const String joinCode = 'Join Code';
  static const String totalExpenses = 'Total Expenses';
  static const String myContribution = 'My Contribution';
  static const String pullToRefresh = 'Pull to refresh';
  static const String joinRequestsLabel = 'Join Requests';
  static const String flatSettingsLabel = 'Flat Settings';
  static const String memberCount = 'Members';

  // Flat — members
  static const String flatMembersTitle = 'Members';
  static const String managerRole = 'Manager';
  static const String coManagerRole = 'Co-Manager';
  static const String memberRole = 'Member';
  static const String contribution = 'Contribution';

  // Flat — join requests (manager)
  static const String joinRequestsTitle = 'Join Requests';
  static const String approveLabel = 'Approve';
  static const String declineLabel = 'Decline';
  static const String noJoinRequests = 'No pending join requests.';
  static const String approveRequestTitle = 'Approve Request';
  static const String approveRequestMessage =
      "The flat's fixed contribution will be split equally among all members.";
  static const String setContributionLabel = 'Fixed contribution (BDT)';
  static const String setContributionHint = '0 if paying nothing this month';
  static const String requestApprovedMsg = 'Member added successfully!';
  static const String requestDeclinedMsg = 'Request declined.';

  // Flat — fixed expenses
  static const String fixedExpensesTitle = 'Fixed Expenses';
  static const String addExpenseLabel = 'Add Expense';
  static const String expenseTypeLabel = 'Expense type';
  static const String expenseTypeHint = 'e.g. Rent, WiFi, Electricity';
  static const String amountLabel = 'Amount (BDT)';
  static const String amountHint = '0.00';
  static const String noExpenses = 'No fixed expenses added yet.';
  static const String expenseAddedMsg = 'Expense added.';
  static const String expenseUpdatedMsg = 'Expense updated.';
  static const String expenseDeletedMsg = 'Expense deleted.';
  static const String redistributedMsg = 'Contributions redistributed.';
  static const String redistributeLabel = 'Redistribute Equally';
  static const String deleteExpenseConfirmTitle = 'Delete Expense?';
  static const String deleteExpenseConfirmMsg =
      'This will recalculate all member contributions.';
  static const String editExpenseTitle = 'Edit Expense';

  // Wallet — general
  static const String walletTitle = 'My Wallet';
  static const String flatWalletTitle = 'Flat Cash Pool';
  static const String walletCurrentBalance = 'Your current balance';
  static const String payNow = 'Pay Now';
  static const String suggestedDeposit = 'Suggested deposit this month';
  static const String recentActivity = 'Recent Activity';
  static const String seeAllTransactions = 'See All Transactions';
  static const String paymentRequestsTitle = 'Payment Requests';
  static const String allWalletsTitle = 'Member Wallets';
  static const String paymentsListTitle = 'Payments';

  // Wallet — submit payment
  static const String submitPaymentTitle = 'Submit Payment';
  static const String submitPaymentLabel = 'Submit Payment';
  static const String paymentAmountLabel = 'Amount (BDT)';
  static const String paymentMethodLabel = 'Payment Method';
  static const String paymentNoteLabel = 'Transaction ID or note (recommended)';
  static const String paymentSubmittedMsg =
      'Payment submitted! Awaiting manager verification.';
  static const String awaitingVerification = 'Awaiting Verification';
  static const String paymentVerifiedStatus = 'Verified';
  static const String paymentRejectedStatus = 'Rejected';
  static const String paymentPendingStatus = 'Pending';

  // Wallet — manager payments
  static const String verifyPaymentLabel = 'Verify';
  static const String rejectPaymentLabel = 'Reject';
  static const String verifyConfirmTitle = 'Confirm Verification';
  static const String rejectReasonLabel = 'Reason (optional)';
  static const String paymentVerifiedMsg = 'Payment verified successfully.';
  static const String paymentRejectedMsg = 'Payment rejected.';

  // Wallet — transactions
  static const String transactionHistoryTitle = 'Transaction History';

  // Wallet — payment hints
  static const String paymentHintsTitle = 'Payment Hints';
  static const String suggestedMealLabel = 'Monthly meal estimate per person';
  static const String suggestedHouseholdLabel =
      'Monthly household expenses estimate';
  static const String paymentHintsUpdatedMsg = 'Payment hints updated.';
  static const String flatWalletNegativeTooltip =
      'Flat wallet is in deficit. Members need to deposit before expenses can be cleared.';

  static const String paymentHintsHelperNote =
      'These are display-only suggestions. They guide members on how much to deposit. Changing them does not trigger any deductions.';

  // Wallet — new payment request
  static const String newPaymentRequestTitle = 'New Payment Request';
  static const String requestToLabel = 'Request to';
  static const String requestPurposeLabel = 'What is this payment for?';
  static const String sendRequestLabel = 'Send Request';
  static const String paymentRequestSentMsg = 'Payment request sent.';
  static const String cancelRequestMsg =
      'Cancel this request? Any linked pending payment will also be cancelled.';
  static const String paymentRequestCancelledMsg = 'Request cancelled.';

  // Flat — settings
  static const String flatSettingsTitle = 'Flat Settings';
  static const String updateFlatLabel = 'Save Changes';
  static const String flatUpdatedMsg = 'Flat updated.';
  static const String deleteFlatLabel = 'Delete Flat';
  static const String deleteFlatConfirmTitle = 'Delete Flat?';
  static const String deleteFlatConfirmMsg =
      'This permanently deletes the flat. All members must leave first.';
  static const String flatDeletedMsg = 'Flat deleted.';

  // Expense module
  static const String expenseListTitle = 'Expenses';
  static const String expenseDetailTitle = 'Expense Detail';
  static const String recordExpenseTitle = 'Record Expense';
  static const String noExpensesRecorded = 'No expenses recorded.';
  static const String categoryLabel = 'Category';
  static const String descriptionLabel = 'Description (optional)';
  static const String descriptionHint = 'e.g. Market shopping';
  static const String approveExpenseLabel = 'Approve Expense';
  static const String deleteExpenseLabel = 'Delete Expense';
  static const String recordExpenseLabel = 'Record Expense';
  static const String expenseRecordedMsg = 'Expense recorded successfully.';
  static const String expenseApprovedMsg = 'Expense approved successfully.';
  static const String expensesActionLabel = 'Expenses';
}
