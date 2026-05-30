import 'package:equatable/equatable.dart';

class AuditLogEntity extends Equatable {
  const AuditLogEntity({
    required this.id,
    required this.action,
    required this.createdAt,
    this.entityType,
    this.entityId,
    this.performedBy,
    this.performedByName,
    this.oldValue,
    this.newValue,
  });

  final String id;
  final String action;
  final String? entityType;
  final String? entityId;
  final String? performedBy;
  final String? performedByName;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final String createdAt;

  @override
  List<Object?> get props => [
        id,
        action,
        entityType,
        entityId,
        performedBy,
        performedByName,
        oldValue,
        newValue,
        createdAt,
      ];
}
