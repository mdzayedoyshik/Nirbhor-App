import '../../../complaint/domain/entities/complaint_entity.dart';

class ComplaintPageArgs {
  const ComplaintPageArgs({
    required this.flatId,
    required this.canManage,
    required this.myMemberId,
  });

  final String flatId;
  final bool canManage;
  final String myMemberId;
}

class ComplaintDetailArgs {
  const ComplaintDetailArgs({
    required this.flatId,
    required this.complaint,
    required this.canManage,
    required this.myMemberId,
  });

  final String flatId;
  final ComplaintEntity complaint;
  final bool canManage;
  final String myMemberId;
}
