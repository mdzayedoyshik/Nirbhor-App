import '../entities/audit_log_entity.dart';
import '../repositories/audit_log_repository.dart';

class GetAuditLogParams {
  const GetAuditLogParams({
    required this.flatId,
    required this.logId,
  });

  final String flatId;
  final String logId;
}

class GetAuditLogUseCase {
  GetAuditLogUseCase(this._repository);

  final AuditLogRepository _repository;

  Future<AuditLogEntity> call(GetAuditLogParams params) =>
      _repository.getAuditLog(
        flatId: params.flatId,
        logId: params.logId,
      );
}
