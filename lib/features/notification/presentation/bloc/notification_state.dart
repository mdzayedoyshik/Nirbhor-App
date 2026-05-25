import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_entity.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationUnreadCountLoaded extends NotificationState {
  const NotificationUnreadCountLoaded(this.unreadCount);

  final int unreadCount;

  @override
  List<Object?> get props => [unreadCount];
}

class NotificationListLoading extends NotificationState {
  const NotificationListLoading();
}

class NotificationListLoaded extends NotificationState {
  const NotificationListLoaded({
    required this.notifications,
    required this.total,
    required this.page,
    required this.hasMore,
    required this.isLoadingMore,
    required this.unreadCount,
  });

  final List<NotificationEntity> notifications;
  final int total;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final int unreadCount;

  NotificationListLoaded copyWith({
    List<NotificationEntity>? notifications,
    int? total,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    int? unreadCount,
  }) {
    return NotificationListLoaded(
      notifications: notifications ?? this.notifications,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        total,
        page,
        hasMore,
        isLoadingMore,
        unreadCount,
      ];
}

class NotificationError extends NotificationState {
  const NotificationError({
    required this.message,
    this.notifications,
    this.unreadCount = 0,
  });

  final String message;
  final List<NotificationEntity>? notifications;
  final int unreadCount;

  @override
  List<Object?> get props => [message, notifications, unreadCount];
}
