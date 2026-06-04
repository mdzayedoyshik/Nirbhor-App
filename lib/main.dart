import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nirbhor/features/flat/presentation/bloc/join_requests_bloc.dart';
import 'package:nirbhor/features/summary/presentation/bloc/summary_bloc.dart';

import 'core/di/injection_container.dart';
import 'core/env/app_env.dart';
import 'core/router/app_router.dart';
import 'core/services/analytics_service.dart';
import 'core/services/bloc_crashlytics_observer.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/remote_config_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/profile_bloc.dart';
import 'features/flat/presentation/bloc/flat_bloc.dart';
import 'features/wallet/presentation/bloc/wallet/wallet_bloc.dart';
import 'firebase_options.dart';

// Must be a top-level function for FCM background isolate
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // No BLoC/DI access here — runs in a separate isolate.
  // Firebase is already initialized by the plugin before this is called.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const envStr = String.fromEnvironment('ENV', defaultValue: 'dev');
  await AppEnv.init(
    env: envStr == 'prod' ? AppEnvironment.prod : AppEnvironment.dev,
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // Disable both Crashlytics and Analytics in debug builds to avoid
  // polluting production datasets with local dev data.
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);

  // Catch Flutter framework errors (widget build, layout, painting).
  // Use recordFlutterFatalError so crashes appear in the Crashes dashboard,
  // not just the Non-fatal section.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Catch async Dart errors outside the Flutter framework (e.g. native
  // callbacks, background futures, isolate errors).
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Fetch remote config concurrently with the rest of startup so it is ready
  // by the time the splash screen finishes.
  await RemoteConfigService.instance.initialize();

  await GoogleSignIn.instance.initialize(serverClientId: AppEnv.googleClientId);

  await configureDependencies();

  Bloc.observer = BlocCrashlyticsObserver(sl<AnalyticsService>());

  sl<AuthBloc>().add(const AuthSessionCheckRequested());

  // Load theme before rendering so there is no flash.
  final themeCubit = ThemeCubit();
  await themeCubit.loadSavedTheme();

  final router = createRouter(sl<AuthBloc>());
  runApp(NirbhorApp(router: router, themeCubit: themeCubit));

  // Wire up push notification deep-linking after runApp so the widget tree
  // is ready.  The service requests FCM permission, sets up onMessage /
  // onMessageOpenedApp / getInitialMessage, and stores the router reference
  // for later navigation.
  await PushNotificationService.instance.initialize(router);
}

class NirbhorApp extends StatelessWidget {
  final GoRouter router;
  final ThemeCubit themeCubit;

  const NirbhorApp({super.key, required this.router, required this.themeCubit});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: themeCubit),
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
        BlocProvider<ProfileBloc>.value(value: sl<ProfileBloc>()),
        BlocProvider<FlatBloc>.value(value: sl<FlatBloc>()),
        BlocProvider<WalletBloc>.value(value: sl<WalletBloc>()),
        BlocProvider<JoinRequestsBloc>.value(value: sl<JoinRequestsBloc>()),
        BlocProvider<SummaryBloc>.value(value: sl<SummaryBloc>()),
      ],
      child: _AppView(router: router),
    );
  }
}

// Separated so BlocListener has MultiBlocProvider in its ancestor tree.
class _AppView extends StatefulWidget {
  final GoRouter router;
  const _AppView({required this.router});

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // FlatBloc check is triggered here; navigation is handled by the
        // router's redirect + refreshListenable (via _AuthNotifier).
        if (state is AuthAuthenticated) {
          context.read<FlatBloc>().add(
            FlatCheckRequested(userId: state.user.id),
          );
        }
      },
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'Nirbhor',
            debugShowCheckedModeBanner: false,
            routerConfig: widget.router,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeState.mode,
          );
        },
      ),
    );
  }
}
