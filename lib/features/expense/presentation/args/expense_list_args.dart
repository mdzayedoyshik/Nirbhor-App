class ExpenseListArgs {
  const ExpenseListArgs({
    required this.flatId,
    required this.canManage,
  });

  final String flatId;
  final bool canManage;
}
