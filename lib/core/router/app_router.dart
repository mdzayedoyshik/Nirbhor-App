import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/args/complete_setup_page_args.dart';
import '../../features/auth/presentation/args/otp_page_args.dart';
import '../../features/auth/presentation/args/reset_password_page_args.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../core/enums/auth_enums.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/auth/presentation/pages/complete_setup_page.dart';
import '../../features/auth/presentation/pages/email_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/home_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/flat/domain/entities/flat_entity.dart';
import '../../features/flat/domain/entities/flat_preview_entity.dart';
import '../../features/flat/presentation/cubit/fixed_expenses_cubit.dart';
import '../../features/flat/presentation/cubit/flat_preview_cubit.dart';
import '../../features/flat/presentation/cubit/join_requests_cubit.dart';
import '../../features/flat/presentation/pages/create_flat_page.dart';
import '../../features/flat/presentation/pages/fixed_expenses_page.dart';
import '../../features/flat/presentation/pages/flat_members_page.dart';
import '../../features/flat/presentation/pages/flat_preview_page.dart';
import '../../features/flat/presentation/pages/flat_settings_page.dart';
import '../../features/flat/presentation/pages/join_flat_page.dart';
import '../../features/flat/presentation/pages/join_requests_page.dart';
import '../di/injection_container.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const email = '/auth/email';
  static const otp = '/auth/otp';
  static const login = '/auth/login';
  static const completeSetup = '/auth/complete-setup';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const home = '/home';
  static const profile = '/profile';
  static const changePassword = '/profile/change-password';

  // Flat
  static const flatCreate = '/flat/create';
  static const flatJoin = '/flat/join';
  static const flatPreview = '/flat/preview';
  static const flatRequests = '/flat/requests';
  static const flatExpenses = '/flat/expenses';
  static const flatMembers = '/flat/members';
  static const flatSettings = '/flat/settings';
}

GoRouter createRouter(AuthBloc authBloc) {
  final notifier = _AuthNotifier(authBloc.stream);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = authBloc.state;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      // While checking session: keep everything on splash
      if (authState is AuthInitial ||
          (authState is AuthLoading &&
              authState.source == AuthLoadingSource.session)) {
        return isSplash ? null : AppRoutes.splash;
      }

      // Auth resolved but still on splash → SplashPage navigates with delay
      if (isSplash) return null;

      // Normal guards for all other routes
      final isAuthenticated = authState is AuthAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      if (isAuthenticated && isAuthRoute) return AppRoutes.home;
      if (!isAuthenticated && !isAuthRoute) return AppRoutes.email;
      return null;
    },
    routes: [
      // ── Splash ────────────────────────────────────────
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),

      // ── Auth ──────────────────────────────────────────
      GoRoute(path: AppRoutes.email, builder: (_, _) => const EmailPage()),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, state) => OtpPage(args: state.extra as OtpPageArgs),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, state) => LoginPage(email: state.extra as String),
      ),
      GoRoute(
        path: AppRoutes.completeSetup,
        builder: (_, state) =>
            CompleteSetupPage(args: state.extra as CompleteSetupPageArgs),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (_, state) =>
            ResetPasswordPage(args: state.extra as ResetPasswordPageArgs),
      ),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfilePage()),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (_, _) => const ChangePasswordPage(),
      ),

      // ── Flat ──────────────────────────────────────────
      GoRoute(
        path: AppRoutes.flatCreate,
        builder: (_, _) => const CreateFlatPage(),
      ),
      GoRoute(
        path: AppRoutes.flatJoin,
        builder: (_, _) => BlocProvider(
          create: (_) => sl<FlatPreviewCubit>(),
          child: const JoinFlatPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.flatPreview,
        builder: (_, state) =>
            FlatPreviewPage(preview: state.extra as FlatPreviewEntity),
      ),
      GoRoute(
        path: AppRoutes.flatRequests,
        builder: (ctx, state) {
          final flatId = state.extra as String;
          return BlocProvider(
            create: (_) => sl<JoinRequestsCubit>(),
            child: JoinRequestsPage(flatId: flatId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.flatExpenses,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BlocProvider(
            create: (_) => sl<FixedExpensesCubit>(),
            child: FixedExpensesPage(
              flatId: extra['flatId'] as String,
              canManage: extra['canManage'] as bool,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.flatMembers,
        builder: (_, state) => FlatMembersPage(flat: state.extra as FlatEntity),
      ),
      GoRoute(
        path: AppRoutes.flatSettings,
        builder: (_, state) =>
            FlatSettingsPage(flat: state.extra as FlatEntity),
      ),
    ],
  );
}

/// Wraps an auth bloc stream as a [ChangeNotifier] so GoRouter's
/// [refreshListenable] re-runs the redirect whenever auth state changes.
class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  _AuthNotifier(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
