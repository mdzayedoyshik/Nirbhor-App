import '../../../flat/domain/entities/flat_member_entity.dart';

class MealPageArgs {
  const MealPageArgs({
    required this.flatId,
    required this.canManage,
    required this.myMemberId,
    required this.members,
  });

  final String flatId;
  final bool canManage;
  final String myMemberId;
  final List<FlatMemberEntity> members;
}
