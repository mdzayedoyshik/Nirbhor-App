import 'package:equatable/equatable.dart';

class AuditLogFilters extends Equatable {
  const AuditLogFilters({
    this.action,
    this.entityType,
  });

  final String? action;
  final String? entityType;

  AuditLogFilters copyWith({
    Object? action = _sentinel,
    Object? entityType = _sentinel,
  }) {
    return AuditLogFilters(
      action: action == _sentinel ? this.action : action as String?,
      entityType:
          entityType == _sentinel ? this.entityType : entityType as String?,
    );
  }

  @override
  List<Object?> get props => [action, entityType];
}

// Sentinel used for copyWith to distinguish null from "not provided"
const _sentinel = Object();

abstract class AuditLogEvent extends Equatable {
  const AuditLogEvent();

  @override
  List<Object?> get props => [];
}

class AuditLogLoadRequested extends AuditLogEvent {
  const AuditLogLoadRequested({
    required this.flatId,
    required this.filters,
  });

  final String flatId;
  final AuditLogFilters filters;

  @override
  List<Object?> get props => [flatId, filters];
}

class AuditLogLoadMoreRequested extends AuditLogEvent {
  const AuditLogLoadMoreRequested();
}

class AuditLogFilterChanged extends AuditLogEvent {
  const AuditLogFilterChanged({
    required this.flatId,
    required this.filters,
  });

  final String flatId;
  final AuditLogFilters filters;

  @override
  List<Object?> get props => [flatId, filters];
}
