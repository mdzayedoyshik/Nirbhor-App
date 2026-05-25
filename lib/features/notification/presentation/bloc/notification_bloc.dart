import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({
    required GetNotificationsUseCase getNotifications,
    required GetUnreadCountUseCase getUnreadCount,
    required MarkNotificationReadUseCase markRead,
    required MarkAllNotificationsReadUseCase markAllRead,
    required DeleteNotificationUseCase deleteNotification,
  })  : _getNotifications = getNotifications,
        _getUnreadCount = getUnreadCount,
        _markRead = markRead,
        _markAllRead = markAllRead,
        _deleteNotification = deleteNotification,
        super(const NotificationInitial()) {
    on<NotificationLoadRequested>(_onLoadRequested);
    on<NotificationLoadMoreRequested>(_onLoadMoreRequested);
    on<NotificationUnreadCountRequested>(_onUnreadCountRequested);
    on<NotificationMarkReadRequested>(_onMarkReadRequested);
    on<NotificationMarkAllReadRequested>(_onMarkAllReadRequested);
    on<NotificationDeleteRequested>(_onDeleteRequested);
  }

  final GetNotificationsUseCase _getNotifications;
  final GetUnreadCountUseCase _getUnreadCount;
  final MarkNotificationReadUseCase _markRead;
  final MarkAllNotificationsReadUseCase _markAllRead;
  final DeleteNotificationUseCase _deleteNotification;

  static const int _limit = 20;

  List<NotificationEntity> _resolveList() {
    final s = state;
    if (s is NotificationListLoaded) return s.notifications;
    if (s is NotificationError) return s.notifications ?? [];
    return [];
  }

  int _resolveUnreadCount() {
    final s = state;
    if (s is NotificationListLoaded) return s.unreadCount;
    if (s is NotificationUnreadCountLoaded) return s.unreadCount;
    if (s is NotificationError) return s.unreadCount;
    return 0;
  }

  Future<void> _onLoadRequested(
    NotificationLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationListLoading());
    try {
      final result = await _getNotifications(
        const GetNotificationsParams(page: 1, limit: _limit),
      );
      final notifications =
          result['notifications'] as List<NotificationEntity>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      final total = pagination['total'] as int? ?? 0;
      final unreadCount = result['unread_count'] as int? ?? 0;
      emit(NotificationListLoaded(
        notifications: notifications,
        total: total,
        page: 1,
        hasMore: notifications.length < total,
        isLoadingMore: false,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationError(
        message: e.toString(),
        notifications: _resolveList(),
        unreadCount: _resolveUnreadCount(),
      ));
    }
  }

  Future<void> _onLoadMoreRequested(
    NotificationLoadMoreRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is! NotificationListLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final result = await _getNotifications(
        GetNotificationsParams(page: nextPage, limit: _limit),
      );
      final newItems = result['notifications'] as List<NotificationEntity>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      final total = pagination['total'] as int? ?? 0;
      final combined = [...current.notifications, ...newItems];
      emit(current.copyWith(
        notifications: combined,
        total: total,
        page: nextPage,
        hasMore: combined.length < total,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onUnreadCountRequested(
    NotificationUnreadCountRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final count = await _getUnreadCount();
      // Only emit the badge state if we don't have a richer list state already
      if (state is NotificationInitial ||
          state is NotificationUnreadCountLoaded) {
        emit(NotificationUnreadCountLoaded(count));
      } else if (state is NotificationListLoaded) {
        emit((state as NotificationListLoaded).copyWith(unreadCount: count));
      }
    } catch (_) {
      // Silently fail — badge will just stay at previous value
    }
  }

  Future<void> _onMarkReadRequested(
    NotificationMarkReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final currentList = _resolveList();
    final currentCount = _resolveUnreadCount();
    final index = currentList.indexWhere((n) => n.id == event.notificationId);
    if (index == -1) return;

    final target = currentList[index];
    if (target.isRead) return; // already read, no-op

    // Optimistic update
    final updated = _replaceAt(currentList, index, _withRead(target, true));
    final newCount = (currentCount - 1).clamp(0, currentCount);
    _emitUpdatedList(emit, updated, newCount);

    try {
      await _markRead(event.notificationId);
    } catch (_) {
      // Revert on error
      final reverted =
          _replaceAt(updated, index, _withRead(target, false));
      _emitUpdatedList(emit, reverted, currentCount);
    }
  }

  Future<void> _onMarkAllReadRequested(
    NotificationMarkAllReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final currentList = _resolveList();
    final optimistic = currentList.map((n) => _withRead(n, true)).toList();
    _emitUpdatedList(emit, optimistic, 0);

    try {
      await _markAllRead();
    } catch (_) {
      // Revert
      _emitUpdatedList(emit, currentList, _resolveUnreadCount());
    }
  }

  Future<void> _onDeleteRequested(
    NotificationDeleteRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final currentList = _resolveList();
    final currentCount = _resolveUnreadCount();
    final index = currentList.indexWhere((n) => n.id == event.notificationId);
    if (index == -1) return;

    final target = currentList[index];
    final newList = [...currentList]..removeAt(index);
    final newCount = target.isRead
        ? currentCount
        : (currentCount - 1).clamp(0, currentCount);
    _emitUpdatedList(emit, newList, newCount);

    try {
      await _deleteNotification(event.notificationId);
    } catch (_) {
      // Revert
      final reverted = [...newList]..insert(index, target);
      _emitUpdatedList(emit, reverted, currentCount);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _emitUpdatedList(
    Emitter<NotificationState> emit,
    List<NotificationEntity> notifications,
    int unreadCount,
  ) {
    final current = state;
    if (current is NotificationListLoaded) {
      emit(current.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } else {
      emit(NotificationListLoaded(
        notifications: notifications,
        total: notifications.length,
        page: 1,
        hasMore: false,
        isLoadingMore: false,
        unreadCount: unreadCount,
      ));
    }
  }

  List<NotificationEntity> _replaceAt(
    List<NotificationEntity> list,
    int index,
    NotificationEntity item,
  ) {
    return [...list]..[index] = item;
  }

  NotificationEntity _withRead(NotificationEntity n, bool isRead) {
    return _ReadOverride(
      id: n.id,
      flatId: n.flatId,
      type: n.type,
      title: n.title,
      message: n.message,
      isRead: isRead,
      referenceId: n.referenceId,
      createdAt: n.createdAt,
    );
  }
}

/// Lightweight wrapper to override [isRead] without modifying the model layer.
class _ReadOverride extends NotificationEntity {
  const _ReadOverride({
    required super.id,
    required super.type,
    required super.title,
    required super.isRead,
    required super.createdAt,
    super.flatId,
    super.message,
    super.referenceId,
  });
}
