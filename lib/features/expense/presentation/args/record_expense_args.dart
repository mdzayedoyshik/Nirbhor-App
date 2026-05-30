class RecordExpenseArgs {
  const RecordExpenseArgs({
    required this.flatId,
    required this.memberCount,
    required this.canManage,
  });

  final String flatId;
  final int memberCount;
  final bool canManage;
}
