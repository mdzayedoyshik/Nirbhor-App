import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../di/injection_container.dart';
import '../router/app_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/expense/presentation/args/expense_list_args.dart';
import '../../features/flat/presentation/bloc/flat_bloc.dart';
import '../../features/notification/presentation/bloc/notification_bloc.dart';
import '../../features/notification/presentation/bloc/notification_event.dart';
import '../../features/summary/presentation/args/summary_page_args.dart';
import '../../features/task/presentation/args/task_page_args.dart';
import '../../features/complaint/presentation/args/complaint_page_args.dart';
import '../../features/wallet/presentation/args/wallet_page_args.dart';

// ─── Foreground push event ────────────────────────────────────────────────────

/// Broadcast when a push notification arrives while the app is in the
/// foreground. Active pages subscribe to [PushNotificationService.foregroundStream]
/// and reload their BLoC data when a relevant type is received.
class ForegroundPushEvent {
  const ForegroundPushEvent({
    required this.type,
    required this.flatId,
    this.referenceId = '',
  });

  final String type;
  final String flatId;
  final String referenceId;

  bool get isTask =>
      type.contains('task');
  bool get isComplaint =>
      type.contains('complaint');
  bool get isPayment =>
      type.contains('payment') ||
      type.contains('wallet') ||
      type.contains('contribution');
}

// ─── Service ──────────────────────────────────────────────────────────────────

/// Singleton that handles Firebase Cloud Messaging for all three app states:
///
/// • **Foreground** – `onMessage`: refreshes the notification list & badge;
///   broadcasts a [ForegroundPushEvent] so open feature pages can reload.
///
/// • **Background** – `onMessageOpenedApp`: navigates to the relevant screen.
///
/// • **Terminated** – `getInitialMessage`: waits for auth + flat to be ready,
///   then navigates.
///
/// Call [initialize] once in `main()` after `runApp`.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _foregroundController = StreamController<ForegroundPushEvent>.broadcast();

  /// Listen here inside [State.initState] to refresh feature BLoCs when a
  /// relevant push arrives while the page is visible.
  Stream<ForegroundPushEvent> get foregroundStream => _foregroundController.stream;

  GoRouter? _router;

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> initialize(GoRouter router) async {
    _router = router;

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground: notification arrives while app is open
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Background: user taps a notification while app is backgrounded
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Terminated: app was launched by tapping a notification
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _navigateWhenReady(initial);
    }
  }

  void dispose() {
    _foregroundController.close();
  }

  // ── Private handlers ───────────────────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final type = (data['type'] as String? ?? '').toLowerCase();
    final flatId = data['flat_id'] as String? ?? '';
    final referenceId = data['reference_id'] as String? ?? '';

    // 1. Always refresh the notification badge and list
    sl<NotificationBloc>()
      ..add(const NotificationUnreadCountRequested())
      ..add(const NotificationLoadRequested());

    // 2. Broadcast to any open feature page that wants to reload its data
    if (type.isNotEmpty) {
      _foregroundController.add(
        ForegroundPushEvent(type: type, flatId: flatId, referenceId: referenceId),
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _navigateFromMessage(message);
  }

  // ── Terminated-state helper ────────────────────────────────────────────────

  /// Waits for [FlatBloc] to reach [FlatLoaded] before navigating,
  /// so the app has context (canManage, myMemberId) for the target screen.
  void _navigateWhenReady(RemoteMessage message) {
    final flatState = sl<FlatBloc>().state;
    if (flatState is FlatLoaded || flatState is FlatPendingExit) {
      // Flat is already loaded — navigate after the first frame
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _navigateFromMessage(message),
      );
      return;
    }

    // Flat is not yet loaded; listen until it is
    StreamSubscription<FlatState>? sub;
    sub = sl<FlatBloc>().stream.listen((state) {
      if (state is FlatLoaded || state is FlatPendingExit) {
        sub?.cancel();
        _navigateFromMessage(message);
      }
    });
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _navigateFromMessage(RemoteMessage message) {
    final router = _router;
    if (router == null) return;

    final data    = message.data;
    final type    = (data['type'] as String? ?? '').toLowerCase();
    final flatId  = data['flat_id'] as String? ?? '';

    if (flatId.isEmpty) { router.go(AppRoutes.home); return; }

    // Resolve flat + user context from singleton BLoCs
    final flatState = sl<FlatBloc>().state;
    final flat = switch (flatState) {
      FlatLoaded(:final flat)      => flat,
      FlatPendingExit(:final flat) => flat,
      _                            => null,
    };

    if (flat == null || flat.id != flatId) {
      router.go(AppRoutes.home);
      return;
    }

    final authState = sl<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      router.go(AppRoutes.home);
      return;
    }

    final member      = flat.memberByUserId(authState.user.id);
    final canManage   = member?.canManage ?? false;
    final myMemberId  = member?.flatMemberId ?? '';

    // ── Route by type (mirrors notification_page._handleTap) ────────────────

    if (type.contains('join_request')) {
      if (canManage) {
        router.push(AppRoutes.flatRequests, extra: flatId);
      } else {
        router.go(AppRoutes.home);
      }
      return;
    }

    if (type == 'member_joined') {
      router.push(AppRoutes.flatMembers, extra: flat);
      return;
    }

    if (type.contains('exit')) {
      // Home auto-renders PendingExitPage when FlatState is FlatPendingExit
      router.go(AppRoutes.home);
      return;
    }

    if (type.contains('task')) {
      router.push(
        AppRoutes.tasks,
        extra: TaskPageArgs(
          flatId: flatId,
          canManage: canManage,
          myMemberId: myMemberId,
          members: flat.activeMembers,
        ),
      );
      return;
    }

    if (type.contains('complaint')) {
      router.push(
        AppRoutes.complaints,
        extra: ComplaintPageArgs(
          flatId: flatId,
          canManage: canManage,
          myMemberId: myMemberId,
        ),
      );
      return;
    }

    if (type.contains('payment') ||
        type.contains('wallet') ||
        type.contains('contribution')) {
      if (type == 'payment_submitted') {
        router.push(
          AppRoutes.walletRequests,
          extra: WalletPageArgs(flatId: flatId, canManage: canManage, initialTab: 1),
        );
      } else if (type == 'payment_request_received') {
        router.push(
          AppRoutes.walletRequests,
          extra: WalletPageArgs(flatId: flatId, canManage: canManage),
        );
      } else {
        router.push(
          AppRoutes.walletHome,
          extra: WalletPageArgs(flatId: flatId, canManage: canManage),
        );
      }
      return;
    }

    if (type.contains('expense')) {
      router.push(
        AppRoutes.expenses,
        extra: ExpenseListArgs(flatId: flatId, canManage: canManage),
      );
      return;
    }

    if (type.contains('month_closed') || type.contains('monthly')) {
      // Extract month + year from FCM data payload so the summary page opens
      // directly on the closed month rather than the current month.
      final initialMonth = int.tryParse(data['month'] as String? ?? '');
      final initialYear  = int.tryParse(data['year']  as String? ?? '');
      router.push(
        AppRoutes.summary,
        extra: SummaryPageArgs(
          flatId: flatId,
          isManager: canManage,
          myMemberId: myMemberId,
          initialMonth: initialMonth,
          initialYear: initialYear,
        ),
      );
      return;
    }

    router.go(AppRoutes.home);
  }
}
