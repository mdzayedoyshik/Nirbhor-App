import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class FeedbackRemoteDataSource {
  FeedbackRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<void> submitFeedback({
    required String type,
    String? title,
    required String description,
    String? appVersion,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'description': description,
      'title': ?title?.isNotEmpty == true ? title : null,
      'app_version': ?appVersion,
    };
    await _apiClient.post(ApiEndpoints.feedback, body, auth: true);
  }
}
