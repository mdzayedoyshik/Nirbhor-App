import '../../domain/entities/audit_log_entity.dart';

class AuditLogModel extends AuditLogEntity {
  const AuditLogModel({
    required super.id,
    required super.action,
    required super.createdAt,
    super.entityType,
    super.entityId,
    super.performedBy,
    super.performedByName,
    super.oldValue,
    super.newValue,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as String,
      action: json['action'] as String,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      performedBy: json['performed_by'] as String?,
      performedByName: json['performed_by_name'] as String?,
      oldValue: json['old_value'] as Map<String, dynamic>?,
      newValue: json['new_value'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
