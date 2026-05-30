import 'package:equatable/equatable.dart';

import '../../domain/entities/audit_log_entity.dart';
import 'audit_log_event.dart';

abstract class AuditLogState extends Equatable {
  const AuditLogState();

  @override
  List<Object?> get props => [];
}

class AuditLogInitial extends AuditLogState {
  const AuditLogInitial();
}

class AuditLogLoading extends AuditLogState {
  const AuditLogLoading();
}

class AuditLogLoaded extends AuditLogState {
  const AuditLogLoaded({
    required this.logs,
    required this.total,
    required this.page,
    required this.hasMore,
    required this.isLoadingMore,
    required this.filters,
  });

  final List<AuditLogEntity> logs;
  final int total;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final AuditLogFilters filters;

  AuditLogLoaded copyWith({
    List<AuditLogEntity>? logs,
    int? total,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    AuditLogFilters? filters,
  }) {
    return AuditLogLoaded(
      logs: logs ?? this.logs,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filters: filters ?? this.filters,
    );
  }

  @override
  List<Object?> get props => [logs, total, page, hasMore, isLoadingMore, filters];
}

class AuditLogError extends AuditLogState {
  const AuditLogError({
    required this.message,
    this.logs,
  });

  final String message;
  final List<AuditLogEntity>? logs;

  @override
  List<Object?> get props => [message, logs];
}
