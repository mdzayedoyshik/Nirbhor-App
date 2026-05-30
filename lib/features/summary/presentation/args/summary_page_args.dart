class SummaryPageArgs {
  const SummaryPageArgs({
    required this.flatId,
    required this.isManager,
    required this.myMemberId,
    this.initialMonth,
    this.initialYear,
  });

  final String flatId;
  final bool isManager;
  final String myMemberId;

  /// When provided (e.g. from a `month_closed` push notification), the summary
  /// page opens on this month directly instead of the current month.
  final int? initialMonth;
  final int? initialYear;
}
