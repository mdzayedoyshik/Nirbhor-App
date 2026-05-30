import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nirbhor/features/flat/presentation/bloc/join_requests_bloc.dart';
import 'package:nirbhor/features/summary/presentation/bloc/summary_bloc.dart';

import 'core/di/injection_container.dart';
import 'core/env/app_env.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/profile_bloc.dart';
import 'features/flat/presentation/bloc/flat_bloc.dart';
import 'features/wallet/presentation/bloc/wallet/wallet_bloc.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const envStr = String.fromEnvironment('ENV', defaultValue: 'dev');
  await AppEnv.init(
    env: envStr == 'prod' ? AppEnvironment.prod : AppEnvironment.dev,
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await GoogleSignIn.instance.initialize(serverClientId: AppEnv.googleClientId);

  await configureDependencies();

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
class _AppView extends StatelessWidget {
  final GoRouter router;
  const _AppView({required this.router});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // FlatBloc check is triggered here; navigation is handled by the
        // router's redirect + refreshListenable (via _AuthNotifier).
        if (state is AuthAuthenticated) {
          context.read<FlatBloc>().add(const FlatCheckRequested());
        }
      },
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'Nirbhor',
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeState.mode,
          );
        },
      ),
    );
  }
}
