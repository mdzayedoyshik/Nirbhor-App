import '../../domain/entities/audit_log_entity.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../datasources/audit_log_remote_datasource.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  AuditLogRepositoryImpl({required AuditLogRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final AuditLogRemoteDataSource _dataSource;

  @override
  Future<Map<String, dynamic>> getAuditLogs({
    required String flatId,
    int page = 1,
    int limit = 20,
    String? action,
    String? entityType,
    String? userId,
    String? from,
    String? to,
  }) =>
      _dataSource.getAuditLogs(
        flatId: flatId,
        page: page,
        limit: limit,
        action: action,
        entityType: entityType,
        userId: userId,
        from: from,
        to: to,
      );

  @override
  Future<AuditLogEntity> getAuditLog({
    required String flatId,
    required String logId,
  }) =>
      _dataSource.getAuditLog(flatId: flatId, logId: logId);
}
