class ExpenseListArgs {
  const ExpenseListArgs({
    required this.flatId,
    required this.canManage,
    this.memberCount = 0,
  });

  final String flatId;
  final bool canManage;
  final int memberCount;
}
