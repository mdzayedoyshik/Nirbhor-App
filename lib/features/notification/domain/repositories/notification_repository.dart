import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unread,
  });

  Future<int> getUnreadCount();

  Future<NotificationEntity> markNotificationRead(String notificationId);

  Future<int> markAllNotificationsRead();

  Future<void> deleteNotification(String notificationId);
}
