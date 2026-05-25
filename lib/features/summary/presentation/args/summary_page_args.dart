class SummaryPageArgs {
  const SummaryPageArgs({
    required this.flatId,
    required this.isManager,
    required this.myMemberId,
  });

  final String flatId;
  final bool isManager;
  final String myMemberId;
}
