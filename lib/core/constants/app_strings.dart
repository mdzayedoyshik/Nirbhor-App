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

  // Flat — settings
  static const String flatSettingsTitle = 'Flat Settings';
  static const String updateFlatLabel = 'Save Changes';
  static const String flatUpdatedMsg = 'Flat updated.';
  static const String deleteFlatLabel = 'Delete Flat';
  static const String deleteFlatConfirmTitle = 'Delete Flat?';
  static const String deleteFlatConfirmMsg =
      'This permanently deletes the flat. All members must leave first.';
  static const String flatDeletedMsg = 'Flat deleted.';
}
