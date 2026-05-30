import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/audit_log_entity.dart';
import '../../domain/usecases/get_audit_log_usecase.dart';
import '../../domain/usecases/get_audit_logs_usecase.dart';
import 'audit_log_event.dart';
import 'audit_log_state.dart';

class AuditLogBloc extends Bloc<AuditLogEvent, AuditLogState> {
  AuditLogBloc({
    required GetAuditLogsUseCase getAuditLogs,
    required GetAuditLogUseCase getAuditLog,
  })  : _getAuditLogs = getAuditLogs,
        _getAuditLog = getAuditLog,
        super(const AuditLogInitial()) {
    on<AuditLogLoadRequested>(_onLoadRequested);
    on<AuditLogLoadMoreRequested>(_onLoadMoreRequested);
    on<AuditLogFilterChanged>(_onFilterChanged);
  }

  final GetAuditLogsUseCase _getAuditLogs;
  // ignore: unused_field
  final GetAuditLogUseCase _getAuditLog;

  static const int _limit = 20;

  List<AuditLogEntity> _resolveLogs() {
    final s = state;
    if (s is AuditLogLoaded) return s.logs;
    if (s is AuditLogError) return s.logs ?? [];
    return [];
  }

  Future<void> _onLoadRequested(
    AuditLogLoadRequested event,
    Emitter<AuditLogState> emit,
  ) async {
    emit(const AuditLogLoading());
    try {
      final result = await _getAuditLogs(GetAuditLogsParams(
        flatId: event.flatId,
        page: 1,
        limit: _limit,
        action: event.filters.action,
        entityType: event.filters.entityType,
      ));
      final logs = result['audit_logs'] as List<AuditLogEntity>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      final total = pagination['total'] as int? ?? 0;
      emit(AuditLogLoaded(
        logs: logs,
        total: total,
        page: 1,
        hasMore: logs.length < total,
        isLoadingMore: false,
        filters: event.filters,
      ));
    } catch (e) {
      emit(AuditLogError(
        message: e.toString(),
        logs: _resolveLogs(),
      ));
    }
  }

  Future<void> _onLoadMoreRequested(
    AuditLogLoadMoreRequested event,
    Emitter<AuditLogState> emit,
  ) async {
    final current = state;
    if (current is! AuditLogLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final result = await _getAuditLogs(GetAuditLogsParams(
        flatId: _resolveFlatId(current),
        page: nextPage,
        limit: _limit,
        action: current.filters.action,
        entityType: current.filters.entityType,
      ));
      final newItems = result['audit_logs'] as List<AuditLogEntity>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      final total = pagination['total'] as int? ?? 0;
      final combined = [...current.logs, ...newItems];
      emit(current.copyWith(
        logs: combined,
        total: total,
        page: nextPage,
        hasMore: combined.length < total,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onFilterChanged(
    AuditLogFilterChanged event,
    Emitter<AuditLogState> emit,
  ) async {
    emit(const AuditLogLoading());
    try {
      final result = await _getAuditLogs(GetAuditLogsParams(
        flatId: event.flatId,
        page: 1,
        limit: _limit,
        action: event.filters.action,
        entityType: event.filters.entityType,
      ));
      final logs = result['audit_logs'] as List<AuditLogEntity>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      final total = pagination['total'] as int? ?? 0;
      emit(AuditLogLoaded(
        logs: logs,
        total: total,
        page: 1,
        hasMore: logs.length < total,
        isLoadingMore: false,
        filters: event.filters,
      ));
    } catch (e) {
      emit(AuditLogError(
        message: e.toString(),
        logs: _resolveLogs(),
      ));
    }
  }

  /// The flatId is stored inside each log entry or obtained from the current
  /// load event. For load-more, we stash it in the state via the last event's
  /// flatId. Since BLoC doesn't store arbitrary data, we peek at the first
  /// log's metadata or fall back to empty string (will fail at API — callers
  /// should always pass flatId explicitly via AuditLogLoadMoreRequested if
  /// needed; for now we rely on the page-level BlocProvider to have set it).
  String _resolveFlatId(AuditLogLoaded loaded) {
    // flatId is not stored in AuditLogLoaded; it's passed in via events.
    // For load-more to work, we keep a private reference set at load time.
    return _lastFlatId;
  }

  String _lastFlatId = '';

  @override
  void onEvent(AuditLogEvent event) {
    super.onEvent(event);
    if (event is AuditLogLoadRequested) {
      _lastFlatId = event.flatId;
    } else if (event is AuditLogFilterChanged) {
      _lastFlatId = event.flatId;
    }
  }
}
