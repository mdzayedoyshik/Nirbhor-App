import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/args/complete_setup_page_args.dart';
import '../../features/auth/presentation/args/otp_page_args.dart';
import '../../features/auth/presentation/args/reset_password_page_args.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/auth/presentation/pages/complete_setup_page.dart';
import '../../features/auth/presentation/pages/email_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/home_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';

class AppRoutes {
  AppRoutes._();

  static const email = '/auth/email';
  static const otp = '/auth/otp';
  static const login = '/auth/login';
  static const completeSetup = '/auth/complete-setup';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const home = '/home';
  static const profile = '/profile';
  static const changePassword = '/profile/change-password';
}

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.email,
    // redirect only runs on explicit navigation — NOT on every bloc state change.
    // Global auth→home and logout→email transitions are handled by AuthListener
    // in main.dart so that `extra` is never lost due to a router rebuild.
    redirect: (context, state) {
      final authState = authBloc.state;
      if (authState is AuthInitial || authState is AuthLoading) return null;

      final isAuthenticated = authState is AuthAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (isAuthenticated && isAuthRoute) return AppRoutes.home;
      if (!isAuthenticated && !isAuthRoute) return AppRoutes.email;
      return null;
    },
    routes: [
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
    ],
  );
}
