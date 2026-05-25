class ExpenseDetailArgs {
  const ExpenseDetailArgs({
    required this.flatId,
    required this.expenseId,
    required this.canManage,
  });

  final String flatId;
  final String expenseId;
  final bool canManage;
}
