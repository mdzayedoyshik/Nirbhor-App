import 'dart:io';

import '../errors/exceptions.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

class ImageUploadService {
  final ApiClient _apiClient;

  ImageUploadService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Uploads [file] to the server and returns the public URL.
  Future<String> upload(File file) async {
    try {
      final response =
          await _apiClient.uploadFile(ApiEndpoints.upload, file.path);
      final data = response['data'] as Map<String, dynamic>;
      return data['url'] as String;
    } on ServerException {
      rethrow;
    } catch (_) {
      throw const ServerException(message: 'Failed to upload image. Please try again.');
    }
  }
}
