import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_colors.dart';
import 'core/di/injection_container.dart';
import 'core/env/app_env.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/profile_cubit.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const envStr = String.fromEnvironment('ENV', defaultValue: 'dev');
  await AppEnv.init(
    env: envStr == 'prod' ? AppEnvironment.prod : AppEnvironment.dev,
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await configureDependencies();

  sl<AuthBloc>().add(const AuthSessionCheckRequested());

  runApp(NirbhorApp(router: createRouter(sl<AuthBloc>())));
}

class NirbhorApp extends StatelessWidget {
  final GoRouter router;
  const NirbhorApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
        BlocProvider<ProfileCubit>.value(value: sl<ProfileCubit>()),
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
        if (state is AuthAuthenticated) {
          router.go(AppRoutes.home);
        } else if (state is AuthUnauthenticated) {
          router.go(AppRoutes.email);
        }
      },
      child: MaterialApp.router(
        title: 'Nirbhor',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: ThemeData(
          fontFamily: 'Poppins',
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.transparent,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
