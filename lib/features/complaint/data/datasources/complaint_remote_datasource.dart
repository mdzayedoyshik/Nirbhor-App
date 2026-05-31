import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/complaint_model.dart';

class ComplaintRemoteDataSource {
  ComplaintRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getComplaints(
    String flatId, {
    String? status,
    String? raisedBy,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      'status': ?status,
      'raised_by': ?raisedBy,
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final endpoint = '${ApiEndpoints.flatComplaints(flatId)}?$query';
    final response = await _apiClient.get(endpoint, auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return {
      'complaints': (data['complaints'] as List)
          .map((c) => ComplaintModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      'pagination': data['pagination'] as Map<String, dynamic>,
    };
  }

  Future<ComplaintModel> getComplaint(
      String flatId, String complaintId) async {
    final response = await _apiClient.get(
      ApiEndpoints.flatComplaint(flatId, complaintId),
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ComplaintModel.fromJson(data['complaint'] as Map<String, dynamic>);
  }

  Future<ComplaintModel> raiseComplaint({
    required String flatId,
    required String subject,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'subject': subject,
      'description': ?description,
    };
    final response = await _apiClient.post(
      ApiEndpoints.flatComplaints(flatId),
      body,
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ComplaintModel.fromJson(data['complaint'] as Map<String, dynamic>);
  }

  Future<ComplaintModel> updateComplaintStatus({
    required String flatId,
    required String complaintId,
    required String status,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.flatComplaintStatus(flatId, complaintId),
      {'status': status},
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ComplaintModel.fromJson(data['complaint'] as Map<String, dynamic>);
  }

  Future<ComplaintModel> editComplaint({
    required String flatId,
    required String complaintId,
    String? subject,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'subject': ?subject,
      'description': ?description,
    };
    final response = await _apiClient.put(
      ApiEndpoints.flatComplaint(flatId, complaintId),
      body,
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ComplaintModel.fromJson(data['complaint'] as Map<String, dynamic>);
  }

  Future<void> deleteComplaint(String flatId, String complaintId) =>
      _apiClient.delete(
        ApiEndpoints.flatComplaint(flatId, complaintId),
        auth: true,
      );
}
