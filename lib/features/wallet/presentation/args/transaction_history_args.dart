import '../../../flat/domain/entities/flat_member_entity.dart';

class TransactionHistoryArgs {
  const TransactionHistoryArgs({
    required this.flatId,
    required this.myMemberId,
    required this.members,
  });

  final String flatId;

  /// The flat_member_id of the currently logged-in user — selected by default.
  final String myMemberId;

  /// All active members of the flat — used to build the member filter chips.
  final List<FlatMemberEntity> members;
}
