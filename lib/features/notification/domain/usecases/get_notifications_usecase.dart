import '../repositories/notification_repository.dart';

class GetNotificationsParams {
  const GetNotificationsParams({
    this.page = 1,
    this.limit = 20,
    this.unread,
  });

  final int page;
  final int limit;
  final bool? unread;
}

class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Map<String, dynamic>> call(GetNotificationsParams params) =>
      _repository.getNotifications(
        page: params.page,
        limit: params.limit,
        unread: params.unread,
      );
}
