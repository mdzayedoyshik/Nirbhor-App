class NotificationPageArgs {
  const NotificationPageArgs({
    required this.flatId,
    required this.canManage,
    required this.isManager,
    required this.myMemberId,
  });

  final String flatId;
  final bool canManage;
  final bool isManager;
  final String myMemberId;
}
