import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/auth_enums.dart';
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
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/flat/domain/entities/flat_entity.dart';
import '../../features/flat/domain/entities/flat_preview_entity.dart';
import '../../features/flat/presentation/bloc/fixed_expenses_bloc.dart';
import '../../features/flat/presentation/bloc/flat_preview_bloc.dart';
import '../../features/flat/presentation/bloc/join_requests_bloc.dart';
import '../../features/flat/presentation/pages/create_flat_page.dart';
import '../../features/flat/presentation/pages/fixed_expenses_page.dart';
import '../../features/flat/presentation/pages/flat_preview_page.dart';
import '../../features/flat/presentation/pages/flat_settings_page.dart';
import '../../features/flat/presentation/pages/join_flat_page.dart';
import '../../features/flat/presentation/pages/join_requests_page.dart';
import '../../features/member/presentation/args/settlement_page_args.dart';
import '../../features/member/presentation/bloc/member_bloc.dart';
import '../../features/member/presentation/pages/member_list_page.dart';
import '../../features/member/presentation/pages/settlement_page.dart';
import '../../features/wallet/presentation/args/submit_payment_args.dart';
import '../../features/wallet/presentation/args/wallet_page_args.dart';
import '../../features/wallet/presentation/bloc/all_wallets/all_wallets_bloc.dart';
import '../../features/wallet/presentation/bloc/payment_hints/payment_hints_bloc.dart';
import '../../features/wallet/presentation/bloc/payment_requests/payment_requests_bloc.dart';
import '../../features/wallet/presentation/bloc/payments/payments_bloc.dart';
import '../../features/wallet/presentation/bloc/transactions/transactions_bloc.dart';
import '../../features/wallet/presentation/bloc/wallet/wallet_bloc.dart';
import '../../features/wallet/presentation/pages/all_wallets_page.dart';
import '../../features/wallet/presentation/pages/payment_hints_page.dart';
import '../../features/wallet/presentation/pages/payment_requests_page.dart';
import '../../features/wallet/presentation/pages/payments_list_page.dart';
import '../../features/wallet/presentation/pages/submit_payment_page.dart';
import '../../features/wallet/presentation/pages/transaction_history_page.dart';
import '../../features/wallet/presentation/pages/wallet_home_page.dart';
import '../../features/expense/presentation/args/edit_expense_args.dart';
import '../../features/expense/presentation/args/expense_detail_args.dart';
import '../../features/expense/presentation/args/expense_list_args.dart';
import '../../features/expense/presentation/args/record_expense_args.dart';
import '../../features/expense/presentation/bloc/expense_bloc.dart';
import '../../features/expense/presentation/pages/edit_expense_page.dart';
import '../../features/expense/presentation/pages/expense_detail_page.dart';
import '../../features/expense/presentation/pages/expense_list_page.dart';
import '../../features/expense/presentation/pages/record_expense_page.dart';
import '../../features/meal/presentation/args/meal_page_args.dart';
import '../../features/meal/presentation/bloc/meal_bloc.dart';
import '../../features/meal/presentation/bloc/meal_pool_bloc.dart';
import '../../features/meal/presentation/bloc/meal_prefs_bloc.dart';
import '../../features/meal/presentation/pages/meal_page.dart';
import '../../features/summary/presentation/args/summary_page_args.dart';
import '../../features/summary/presentation/bloc/summary_bloc.dart';
import '../../features/summary/presentation/pages/summary_page.dart';
import '../../features/task/presentation/args/task_page_args.dart';
import '../../features/task/presentation/bloc/task_bloc.dart';
import '../../features/task/presentation/pages/task_detail_page.dart';
import '../../features/task/presentation/pages/task_page.dart';
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

  // Wallet
  static const walletHome = '/wallet/home';
  static const walletSubmitPayment = '/wallet/pay';
  static const walletAllWallets = '/wallet/all-wallets';
  static const walletPayments = '/wallet/payments';
  static const walletRequests = '/wallet/requests';
  static const walletTransactions = '/wallet/transactions';
  static const walletHints = '/wallet/hints';

  // Flat
  static const flatCreate = '/flat/create';
  static const flatJoin = '/flat/join';
  static const flatPreview = '/flat/preview';
  static const flatRequests = '/flat/requests';
  static const flatExpenses = '/flat/expenses';
  static const flatMembers = '/flat/members';
  static const flatSettlement = '/flat/settlement';
  static const flatSettings = '/flat/settings';

  // Meal
  static const meals = '/meals';

  // Tasks
  static const tasks = '/tasks';
  static const taskDetail = '/tasks/detail';

  // Summary
  static const summary = '/summary';

  // Expense
  static const expenses = '/expenses';
  static const expenseDetail = '/expenses/detail';
  static const recordExpense = '/expenses/record';
  static const editExpense = '/expenses/edit';
}

GoRouter createRouter(AuthBloc authBloc) {
  final notifier = _AuthNotifier(authBloc.stream);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = authBloc.state;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      if (authState is AuthInitial ||
          (authState is AuthLoading &&
              authState.source == AuthLoadingSource.session)) {
        return isSplash ? null : AppRoutes.splash;
      }

      if (isSplash) return null;

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
        redirect: (_, state) =>
            state.extra is OtpPageArgs ? null : AppRoutes.email,
        builder: (_, state) => OtpPage(args: state.extra! as OtpPageArgs),
      ),
      GoRoute(
        path: AppRoutes.login,
        redirect: (_, state) =>
            state.extra is String ? null : AppRoutes.email,
        builder: (_, state) => LoginPage(email: state.extra! as String),
      ),
      GoRoute(
        path: AppRoutes.completeSetup,
        redirect: (_, state) =>
            state.extra is CompleteSetupPageArgs ? null : AppRoutes.email,
        builder: (_, state) =>
            CompleteSetupPage(args: state.extra! as CompleteSetupPageArgs),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        redirect: (_, state) =>
            state.extra is ResetPasswordPageArgs ? null : AppRoutes.email,
        builder: (_, state) =>
            ResetPasswordPage(args: state.extra! as ResetPasswordPageArgs),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => BlocProvider.value(
          value: sl<WalletBloc>(),
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (_, _) => const ChangePasswordPage(),
      ),

      // ── Wallet ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.walletHome,
        redirect: (_, state) =>
            state.extra is WalletPageArgs ? null : AppRoutes.home,
        builder: (_, state) => BlocProvider.value(
          value: sl<WalletBloc>(),
          child: WalletHomePage(args: state.extra! as WalletPageArgs),
        ),
      ),
      GoRoute(
        path: AppRoutes.walletSubmitPayment,
        redirect: (_, state) =>
            state.extra is SubmitPaymentArgs ? null : AppRoutes.home,
        builder: (_, state) => BlocProvider.value(
          value: sl<WalletBloc>(),
          child: SubmitPaymentPage(args: state.extra! as SubmitPaymentArgs),
        ),
      ),
      GoRoute(
        path: AppRoutes.walletAllWallets,
        redirect: (_, state) =>
            state.extra is WalletPageArgs ? null : AppRoutes.home,
        builder: (_, state) => BlocProvider(
          create: (_) => sl<AllWalletsBloc>(),
          child: AllWalletsPage(args: state.extra! as WalletPageArgs),
        ),
      ),
      GoRoute(
        path: AppRoutes.walletPayments,
        redirect: (_, state) =>
            state.extra is String ? null : AppRoutes.home,
        builder: (_, state) => BlocProvider(
          create: (_) => sl<PaymentsBloc>(),
          child: PaymentsListPage(flatId: state.extra! as String),
        ),
      ),
      GoRoute(
        path: AppRoutes.walletRequests,
        redirect: (_, state) =>
            state.extra is WalletPageArgs ? null : AppRoutes.home,
        builder: (_, state) => BlocProvider(
          create: (_) => sl<PaymentRequestsBloc>(),
          child: PaymentRequestsPage(args: state.extra! as WalletPageArgs),
        ),
      ),
      GoRoute(
        path: AppRoutes.walletTransactions,
        redirect: (_, state) =>
            state.extra is String ? null : AppRoutes.home,
        builder: (_, state) => BlocProvider(
          create: (_) => sl<TransactionsBloc>(),
          child: TransactionHistoryPage(flatId: state.extra! as String),
        ),
      ),
      GoRoute(
        path: AppRoutes.walletHints,
        redirect: (_, state) =>
            state.extra is String ? null : AppRoutes.home,
        builder: (_, state) => BlocProvider(
          create: (_) => sl<PaymentHintsBloc>(),
          child: PaymentHintsPage(flatId: state.extra! as String),
        ),
      ),

      // ── Flat ──────────────────────────────────────────
      GoRoute(
        path: AppRoutes.flatCreate,
        builder: (_, _) => const CreateFlatPage(),
      ),
      GoRoute(
        path: AppRoutes.flatJoin,
        builder: (_, _) => BlocProvider(
          create: (_) => sl<FlatPreviewBloc>(),
          child: const JoinFlatPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.flatPreview,
        redirect: (_, state) =>
            state.extra is FlatPreviewEntity ? null : AppRoutes.flatJoin,
        builder: (_, state) =>
            FlatPreviewPage(preview: state.extra! as FlatPreviewEntity),
      ),
      GoRoute(
        path: AppRoutes.flatRequests,
        redirect: (_, state) =>
            state.extra is String ? null : AppRoutes.flatJoin,
        builder: (ctx, state) {
          final flatId = state.extra! as String;
          return BlocProvider(
            create: (_) => sl<JoinRequestsBloc>(),
            child: JoinRequestsPage(flatId: flatId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.flatExpenses,
        redirect: (_, state) =>
            state.extra is Map<String, dynamic> ? null : AppRoutes.flatJoin,
        builder: (ctx, state) {
          final extra = state.extra! as Map<String, dynamic>;
          return BlocProvider(
            create: (_) => sl<FixedExpensesBloc>(),
            child: FixedExpensesPage(
              flatId: extra['flatId'] as String,
              canManage: extra['canManage'] as bool,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.flatMembers,
        redirect: (_, state) =>
            state.extra is FlatEntity ? null : AppRoutes.flatJoin,
        builder: (_, state) => BlocProvider(
          create: (_) => sl<MemberBloc>(),
          child: MemberListPage(flat: state.extra! as FlatEntity),
        ),
      ),
      GoRoute(
        path: AppRoutes.flatSettlement,
        redirect: (_, state) =>
            state.extra is SettlementPageArgs ? null : AppRoutes.flatMembers,
        builder: (_, state) =>
            SettlementPage(args: state.extra! as SettlementPageArgs),
      ),
      GoRoute(
        path: AppRoutes.flatSettings,
        redirect: (_, state) =>
            state.extra is FlatEntity ? null : AppRoutes.flatJoin,
        builder: (_, state) =>
            FlatSettingsPage(flat: state.extra! as FlatEntity),
      ),

      // ── Meal ─────────────────────────────────────────
      GoRoute(
        path: AppRoutes.meals,
        redirect: (_, state) =>
            state.extra is MealPageArgs ? null : AppRoutes.home,
        builder: (_, state) {
          final args = state.extra! as MealPageArgs;
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<MealBloc>()),
              BlocProvider(create: (_) => sl<MealPoolBloc>()),
              BlocProvider(create: (_) => sl<MealPrefsBloc>()),
            ],
            child: MealPage(args: args),
          );
        },
      ),

      // ── Tasks ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.tasks,
        redirect: (_, state) =>
            state.extra is TaskPageArgs ? null : AppRoutes.home,
        builder: (_, state) {
          final args = state.extra! as TaskPageArgs;
          return BlocProvider(
            create: (_) => sl<TaskBloc>(),
            child: TaskPage(args: args),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.taskDetail,
        redirect: (_, state) =>
            state.extra is TaskDetailArgs ? null : AppRoutes.tasks,
        builder: (_, state) {
          final args = state.extra! as TaskDetailArgs;
          return BlocProvider(
            create: (_) => sl<TaskBloc>(),
            child: TaskDetailPage(args: args),
          );
        },
      ),

      // ── Summary ──────────────────────────────────────
      GoRoute(
        path: AppRoutes.summary,
        redirect: (_, state) =>
            state.extra is SummaryPageArgs ? null : AppRoutes.home,
        builder: (_, state) {
          final args = state.extra! as SummaryPageArgs;
          return BlocProvider(
            create: (_) => sl<SummaryBloc>(),
            child: SummaryPage(args: args),
          );
        },
      ),

      // ── Expense ───────────────────────────────────────
      GoRoute(
        path: AppRoutes.expenses,
        redirect: (_, state) =>
            state.extra is ExpenseListArgs ? null : AppRoutes.home,
        builder: (_, state) {
          final args = state.extra! as ExpenseListArgs;
          return BlocProvider(
            create: (_) => sl<ExpenseBloc>(),
            child: ExpenseListPage(
              flatId: args.flatId,
              canManage: args.canManage,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.expenseDetail,
        redirect: (_, state) =>
            state.extra is ExpenseDetailArgs ? null : AppRoutes.expenses,
        builder: (_, state) {
          final args = state.extra! as ExpenseDetailArgs;
          return BlocProvider(
            create: (_) => sl<ExpenseBloc>(),
            child: ExpenseDetailPage(
              flatId: args.flatId,
              expenseId: args.expenseId,
              canManage: args.canManage,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.recordExpense,
        redirect: (_, state) =>
            state.extra is RecordExpenseArgs ? null : AppRoutes.expenses,
        builder: (_, state) {
          final args = state.extra! as RecordExpenseArgs;
          return BlocProvider(
            create: (_) => sl<ExpenseBloc>(),
            child: RecordExpensePage(
              flatId: args.flatId,
              memberCount: args.memberCount,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editExpense,
        redirect: (_, state) =>
            state.extra is EditExpenseArgs ? null : AppRoutes.expenses,
        builder: (_, state) {
          final args = state.extra! as EditExpenseArgs;
          return BlocProvider(
            create: (_) => sl<ExpenseBloc>(),
            child: EditExpensePage(
              flatId: args.flatId,
              expense: args.expense,
            ),
          );
        },
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
