class WalletPageArgs {
  const WalletPageArgs({
    required this.flatId,
    required this.canManage,
  });

  final String flatId;
  final bool canManage;
}
