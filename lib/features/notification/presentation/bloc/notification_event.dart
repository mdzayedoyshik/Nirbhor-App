import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationLoadRequested extends NotificationEvent {
  const NotificationLoadRequested();
}

class NotificationLoadMoreRequested extends NotificationEvent {
  const NotificationLoadMoreRequested();
}

class NotificationUnreadCountRequested extends NotificationEvent {
  const NotificationUnreadCountRequested();
}

class NotificationMarkReadRequested extends NotificationEvent {
  const NotificationMarkReadRequested(this.notificationId);

  final String notificationId;

  @override
  List<Object?> get props => [notificationId];
}

class NotificationMarkAllReadRequested extends NotificationEvent {
  const NotificationMarkAllReadRequested();
}

class NotificationDeleteRequested extends NotificationEvent {
  const NotificationDeleteRequested(this.notificationId);

  final String notificationId;

  @override
  List<Object?> get props => [notificationId];
}
