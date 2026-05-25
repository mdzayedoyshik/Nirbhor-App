class NotificationPageArgs {
  const NotificationPageArgs({
    required this.flatId,
    required this.canManage,
    required this.myMemberId,
  });

  final String flatId;
  final bool canManage;
  final String myMemberId;
}
