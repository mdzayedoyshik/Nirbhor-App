import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class MemberRemoteDataSource {
  final ApiClient _apiClient;

  MemberRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<Map<String, dynamic>> getMembers(String flatId) =>
      _apiClient.get(ApiEndpoints.flatMembers(flatId), auth: true);

  Future<Map<String, dynamic>> changeRole({
    required String flatId,
    required String memberId,
    required String role,
  }) => _apiClient.put(
    ApiEndpoints.flatMemberRole(flatId, memberId),
    {'role': role},
    auth: true,
  );

  Future<Map<String, dynamic>> transferManager({
    required String flatId,
    required String newManagerId,
  }) => _apiClient.post(
    ApiEndpoints.flatTransferManager(flatId),
    {'new_manager_id': newManagerId},
    auth: true,
  );

  Future<Map<String, dynamic>> initiateExit({
    required String flatId,
    required String memberId,
    double fixedRefund = 0,
  }) => _apiClient.post(
    ApiEndpoints.flatMemberInitiateExit(flatId, memberId),
    {'fixed_refund': fixedRefund},
    auth: true,
  );

  Future<Map<String, dynamic>> getSettlement({
    required String flatId,
    required String memberId,
  }) => _apiClient.get(
    ApiEndpoints.flatMemberSettlement(flatId, memberId),
    auth: true,
  );

  Future<Map<String, dynamic>> finalizeExit({
    required String flatId,
    required String memberId,
  }) => _apiClient.post(
    ApiEndpoints.flatMemberFinalizeExit(flatId, memberId),
    {},
    auth: true,
  );

  Future<Map<String, dynamic>> cancelExit({
    required String flatId,
    required String memberId,
  }) => _apiClient.delete(
    ApiEndpoints.flatMemberExit(flatId, memberId),
    auth: true,
  );

  Future<Map<String, dynamic>> getExitStatus() =>
      _apiClient.get(ApiEndpoints.meExitStatus(), auth: true);

  Future<Map<String, dynamic>> acknowledgeExit() =>
      _apiClient.post(ApiEndpoints.meAcknowledgeExit(), {}, auth: true);

  Future<Map<String, dynamic>> getPendingExits(String flatId) =>
      _apiClient.get(ApiEndpoints.flatMemberPendingExits(flatId), auth: true);
}
