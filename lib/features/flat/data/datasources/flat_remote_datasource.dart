import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class FlatRemoteDataSource {
  final ApiClient _apiClient;

  FlatRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Map<String, dynamic>> getMyFlat() =>
      _apiClient.get(ApiEndpoints.flatsMine, auth: true);

  Future<Map<String, dynamic>> createFlat({
    required String name,
    String? address,
    String? photoUrl,
  }) {
    final body = <String, dynamic>{'name': name};
    if (address != null) body['address'] = address;
    if (photoUrl != null) body['photo_url'] = photoUrl;
    return _apiClient.post(ApiEndpoints.flats, body, auth: true);
  }

  Future<Map<String, dynamic>> getFlat(String flatId) =>
      _apiClient.get(ApiEndpoints.flat(flatId), auth: true);

  Future<Map<String, dynamic>> updateFlat({
    required String flatId,
    String? name,
    String? address,
    String? photoUrl,
  }) {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (address != null) body['address'] = address;
    if (photoUrl != null) body['photo_url'] = photoUrl;
    return _apiClient.put(ApiEndpoints.flat(flatId), body, auth: true);
  }

  Future<Map<String, dynamic>> deleteFlat(String flatId) =>
      _apiClient.delete(ApiEndpoints.flat(flatId), auth: true);

  Future<Map<String, dynamic>> previewFlat(String code) =>
      _apiClient.get(ApiEndpoints.flatsJoinPreview(code), auth: true);

  Future<Map<String, dynamic>> sendJoinRequest(String joinCode) => _apiClient
      .post(ApiEndpoints.flatsJoin, {'join_code': joinCode}, auth: true);

  Future<Map<String, dynamic>> getMyRequests() =>
      _apiClient.get(ApiEndpoints.flatsMyRequests, auth: true);

  Future<Map<String, dynamic>> cancelJoinRequest(String requestId) =>
      _apiClient.delete(ApiEndpoints.flatsJoinRequest(requestId), auth: true);

  Future<Map<String, dynamic>> getJoinRequests(String flatId) =>
      _apiClient.get(ApiEndpoints.flatJoinRequests(flatId), auth: true);

  Future<Map<String, dynamic>> approveJoinRequest({
    required String flatId,
    required String requestId,
    required double fixedContribution,
  }) => _apiClient.post(
    ApiEndpoints.flatJoinRequestApprove(flatId, requestId),
    {'fixed_contribution': fixedContribution},
    auth: true,
  );

  Future<Map<String, dynamic>> declineJoinRequest({
    required String flatId,
    required String requestId,
  }) => _apiClient.post(
    ApiEndpoints.flatJoinRequestDecline(flatId, requestId),
    {},
    auth: true,
  );

  Future<Map<String, dynamic>> getFixedExpenses(String flatId) =>
      _apiClient.get(ApiEndpoints.flatFixedExpenses(flatId), auth: true);

  Future<Map<String, dynamic>> addFixedExpense({
    required String flatId,
    required String expenseType,
    required double amount,
  }) => _apiClient.post(ApiEndpoints.flatFixedExpenses(flatId), {
    'expense_type': expenseType,
    'amount': amount,
  }, auth: true);

  Future<Map<String, dynamic>> updateFixedExpense({
    required String flatId,
    required String expenseId,
    String? expenseType,
    double? amount,
  }) {
    final body = <String, dynamic>{};
    if (expenseType != null) body['expense_type'] = expenseType;
    if (amount != null) body['amount'] = amount;
    return _apiClient.put(
      ApiEndpoints.flatFixedExpense(flatId, expenseId),
      body,
      auth: true,
    );
  }

  Future<Map<String, dynamic>> deleteFixedExpense({
    required String flatId,
    required String expenseId,
  }) => _apiClient.delete(
    ApiEndpoints.flatFixedExpense(flatId, expenseId),
    auth: true,
  );

  Future<Map<String, dynamic>> redistribute(
    String flatId, {
    List<dynamic>? contributions,
  }) {
    final body = contributions != null
        ? {'contributions': contributions}
        : <String, dynamic>{};
    return _apiClient.post(
        ApiEndpoints.flatRedistribute(flatId), body, auth: true);
  }
}
