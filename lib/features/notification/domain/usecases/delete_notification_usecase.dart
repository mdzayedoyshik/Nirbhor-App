import '../repositories/notification_repository.dart';

class DeleteNotificationUseCase {
  DeleteNotificationUseCase(this._repository);

  final NotificationRepository _repository;

  Future<void> call(String notificationId) =>
      _repository.deleteNotification(notificationId);
}
