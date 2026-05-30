import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  MarkNotificationReadUseCase(this._repository);

  final NotificationRepository _repository;

  Future<NotificationEntity> call(String notificationId) =>
      _repository.markNotificationRead(notificationId);
}
