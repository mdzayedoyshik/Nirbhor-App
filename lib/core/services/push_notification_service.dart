import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  bool get isTask => type.contains('task');
  bool get isComplaint => type.contains('complaint');
  bool get isPayment =>
      type.contains('payment') ||
      type.contains('wallet') ||
      type.contains('contribution');
}

// ─── Android notification channel ────────────────────────────────────────────

const _channel = AndroidNotificationChannel(
  'nirbhor_high_importance',
  'Nirbhor Notifications',
  description: 'Flat management alerts and updates',
  importance: Importance.high,
);

// ─── Service ──────────────────────────────────────────────────────────────────

/// Singleton that handles Firebase Cloud Messaging for all three app states:
///
/// • **Foreground** – `onMessage`: shows a local notification banner, refreshes
///   the badge, and broadcasts a [ForegroundPushEvent] so open pages can reload.
///   Tapping the banner navigates just like the background/terminated paths.
///
/// • **Background** – `onMessageOpenedApp`: navigates to the relevant screen.
///
/// • **Terminated** – `getInitialMessage`: waits until the router has settled on
///   `/home` (i.e. SplashPage has already finished its navigation) before
///   pushing the destination, preventing the race where SplashPage's
///   `router.go(home)` overwrites the push.
///
/// Call [initialize] once in `main()` after `runApp`.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _foregroundController = StreamController<ForegroundPushEvent>.broadcast();

  /// Listen here inside [State.initState] to refresh feature BLoCs when a
  /// relevant push arrives while the page is visible.
  Stream<ForegroundPushEvent> get foregroundStream => _foregroundController.stream;

  final _localNotifications = FlutterLocalNotificationsPlugin();
  GoRouter? _router;

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> initialize(GoRouter router) async {
    _router = router;

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Create the Android channel so foreground messages can be displayed.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // onDidReceiveNotificationResponse fires when the user taps a local
    // notification that was shown while the app was in the foreground.
    // The payload is the JSON-encoded FCM data map.
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = Map<String, dynamic>.from(
            jsonDecode(payload) as Map,
          );
          _navigateFromData(data);
        } catch (_) {}
      },
    );

    // Tell iOS to show alerts/badge/sound while app is in foreground.
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
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

    // 1. Show a visible notification banner.
    //    Payload = JSON-encoded FCM data so the tap handler can navigate.
    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(data),
      );
    }

    // 2. Always refresh the notification badge and list.
    sl<NotificationBloc>()
      ..add(const NotificationUnreadCountRequested())
      ..add(const NotificationLoadRequested());

    // 3. Broadcast to any open feature page that wants to reload its data.
    if (type.isNotEmpty) {
      _foregroundController.add(
        ForegroundPushEvent(type: type, flatId: flatId, referenceId: referenceId),
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  // ── Terminated-state helper ────────────────────────────────────────────────

  /// Waits until both conditions are true before navigating:
  ///   1. [FlatBloc] has reached [FlatLoaded] (flat context is available).
  ///   2. The router is already at [AppRoutes.home] (SplashPage has finished).
  ///
  /// Without condition 2, SplashPage's own `router.go(home)` would fire after
  /// our `router.push(destination)` and wipe the destination off the stack,
  /// causing the "flickers to home" bug.
  void _navigateWhenReady(RemoteMessage message) {
    late void Function() check;

    check = () {
      final flatState = sl<FlatBloc>().state;
      final flatReady = flatState is FlatLoaded || flatState is FlatPendingExit;
      final path =
          _router?.routerDelegate.currentConfiguration.uri.path ?? '';
      final atHome = path == AppRoutes.home;

      if (flatReady && atHome) {
        _router?.routerDelegate.removeListener(check);
        // One extra frame so the home page finishes building before we push.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _navigateFromData(message.data),
        );
      }
    };

    // Listen to every router navigation via the delegate (ChangeNotifier).
    _router?.routerDelegate.addListener(check);
    // Also evaluate immediately in case we're already in the right state.
    check();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _navigateFromData(Map<String, dynamic> data) {
    final router = _router;
    if (router == null) return;

    final type   = (data['type']   as String? ?? '').toLowerCase();
    final flatId = (data['flat_id'] as String? ?? '');

    if (flatId.isEmpty) { router.go(AppRoutes.home); return; }

    // Resolve flat + user context from singleton BLoCs.
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

    final member     = flat.memberByUserId(authState.user.id);
    final canManage  = member?.canManage ?? false;
    final myMemberId = member?.flatMemberId ?? '';

    // ── Route by type (mirrors notification_page._handleTap) ───────────────

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
