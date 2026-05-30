class WalletPageArgs {
  const WalletPageArgs({
    required this.flatId,
    required this.canManage,
    this.initialTab = 0,
  });

  final String flatId;
  final bool canManage;

  /// Index of the tab to open on the PaymentsHubPage.
  /// 0 = Pending, 1 = Awaiting, 2 = Verified, 3 = Rejected.
  final int initialTab;
}
