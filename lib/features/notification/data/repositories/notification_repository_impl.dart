import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required NotificationRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final NotificationRemoteDataSource _dataSource;

  @override
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unread,
  }) =>
      _dataSource.getNotifications(page: page, limit: limit, unread: unread);

  @override
  Future<int> getUnreadCount() => _dataSource.getUnreadCount();

  @override
  Future<NotificationEntity> markNotificationRead(String notificationId) =>
      _dataSource.markNotificationRead(notificationId);

  @override
  Future<int> markAllNotificationsRead() =>
      _dataSource.markAllNotificationsRead();

  @override
  Future<void> deleteNotification(String notificationId) =>
      _dataSource.deleteNotification(notificationId);
}
