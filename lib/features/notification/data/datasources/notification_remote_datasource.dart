import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unread,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (unread != null) 'unread': '$unread',
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final endpoint = '${ApiEndpoints.notifications}?$query';
    final response = await _apiClient.get(endpoint, auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return {
      'notifications': (data['notifications'] as List)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList(),
      'pagination': data['pagination'] as Map<String, dynamic>,
      'unread_count': data['unread_count'] as int? ?? 0,
    };
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(
      ApiEndpoints.notificationsUnreadCount,
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return data['unread_count'] as int? ?? 0;
  }

  Future<NotificationModel> markNotificationRead(String notificationId) async {
    final response = await _apiClient.patch(
      ApiEndpoints.notificationRead(notificationId),
      const {},
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return NotificationModel.fromJson(
        data['notification'] as Map<String, dynamic>);
  }

  Future<int> markAllNotificationsRead() async {
    final response = await _apiClient.patch(
      ApiEndpoints.notificationsReadAll,
      const {},
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return data['updated_count'] as int? ?? 0;
  }

  Future<void> deleteNotification(String notificationId) =>
      _apiClient.delete(
        ApiEndpoints.notification(notificationId),
        auth: true,
      );
}
