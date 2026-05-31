import '../../../flat/domain/entities/flat_member_entity.dart';

class AuditLogPageArgs {
  const AuditLogPageArgs({
    required this.flatId,
    this.members = const [],
  });

  final String flatId;
  final List<FlatMemberEntity> members;
}
