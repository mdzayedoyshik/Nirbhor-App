import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/audit_log_model.dart';

class AuditLogRemoteDataSource {
  AuditLogRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getAuditLogs({
    required String flatId,
    int page = 1,
    int limit = 20,
    String? action,
    String? entityType,
    String? userId,
    String? from,
    String? to,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (action != null) 'action': action,
      if (entityType != null) 'entity_type': entityType,
      if (userId != null) 'user_id': userId,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final endpoint = '${ApiEndpoints.flatAuditLogs(flatId)}?$query';
    final response = await _apiClient.get(endpoint, auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return {
      'audit_logs': (data['audit_logs'] as List)
          .map((l) => AuditLogModel.fromJson(l as Map<String, dynamic>))
          .toList(),
      'pagination': data['pagination'] as Map<String, dynamic>,
    };
  }

  Future<AuditLogModel> getAuditLog({
    required String flatId,
    required String logId,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.flatAuditLog(flatId, logId),
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return AuditLogModel.fromJson(data['audit_log'] as Map<String, dynamic>);
  }
}
