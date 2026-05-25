import '../entities/audit_log_entity.dart';

abstract class AuditLogRepository {
  Future<Map<String, dynamic>> getAuditLogs({
    required String flatId,
    int page = 1,
    int limit = 20,
    String? action,
    String? entityType,
    String? userId,
    String? from,
    String? to,
  });

  Future<AuditLogEntity> getAuditLog({
    required String flatId,
    required String logId,
  });
}
