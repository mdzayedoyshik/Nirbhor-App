import '../repositories/audit_log_repository.dart';

class GetAuditLogsParams {
  const GetAuditLogsParams({
    required this.flatId,
    this.page = 1,
    this.limit = 20,
    this.action,
    this.entityType,
    this.userId,
    this.from,
    this.to,
  });

  final String flatId;
  final int page;
  final int limit;
  final String? action;
  final String? entityType;
  final String? userId;
  final String? from;
  final String? to;
}

class GetAuditLogsUseCase {
  GetAuditLogsUseCase(this._repository);

  final AuditLogRepository _repository;

  Future<Map<String, dynamic>> call(GetAuditLogsParams params) =>
      _repository.getAuditLogs(
        flatId: params.flatId,
        page: params.page,
        limit: params.limit,
        action: params.action,
        entityType: params.entityType,
        userId: params.userId,
        from: params.from,
        to: params.to,
      );
}
