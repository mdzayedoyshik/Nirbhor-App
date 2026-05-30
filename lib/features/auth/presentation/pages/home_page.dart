import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../features/flat/presentation/bloc/flat_bloc.dart';
import '../../../../features/flat/presentation/bloc/join_requests_bloc.dart';
import '../../../../features/flat/presentation/pages/flat_home_view.dart';
import '../../../../features/flat/presentation/pages/flat_landing_view.dart';
import '../../../../features/flat/presentation/pages/pending_request_view.dart';
import '../../../../features/meal/presentation/bloc/meal_bloc.dart';
import '../../../../features/meal/presentation/bloc/meal_pool_bloc.dart';
import '../../../../features/member/presentation/pages/exit_summary_page.dart';
import '../../../../features/member/presentation/pages/pending_exit_page.dart';
import '../../../../features/wallet/presentation/bloc/wallet/wallet_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Ensures JoinRequestsBloc is loaded only once per flat session;
  // the bloc re-fetches internally after every approve/decline.
  bool _joinRequestsLoaded = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlatBloc, FlatState>(
      listener: (context, state) {
        final resolved = _resolveDisplay(state);
        if (resolved is FlatLoaded) {
          // Refresh wallet summary whenever flat becomes visible
          context.read<WalletBloc>().add(WalletSummaryRequested(resolved.flat.id));
          // Eagerly load today's meal log + current-month pool for home stat card
          final now = DateTime.now();
          final todayStr =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          context.read<MealBloc>().add(MealDailyLoadRequested(
                flatId: resolved.flat.id,
                date: todayStr,
              ));
          context.read<MealPoolBloc>().add(MealPoolLoadRequested(
                flatId: resolved.flat.id,
                month: now.month,
                year: now.year,
              ));
          // Load join-requests badge only once; bloc self-refreshes after approve/decline
          if (!_joinRequestsLoaded) {
            _joinRequestsLoaded = true;
            context
                .read<JoinRequestsBloc>()
                .add(JoinRequestsLoadRequested(resolved.flat.id));
          }
        }
        if (state is FlatError) {
          AppSnackbar.error(context, state.message);
        }
        if (state is FlatNone && _wasRequest(context)) {
          AppSnackbar.success(context, 'Join request cancelled.');
        }
      },
      builder: (context, state) {
        final displayState = _resolveDisplay(state);

        if (displayState is FlatChecking || displayState is FlatInitial) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (displayState is FlatLoaded) {
          return MultiBlocProvider(
            providers: [
              // BlocProvider.value — singleton shared with JoinRequestsPage;
              // .value never closes the bloc when this widget is removed.
              BlocProvider.value(value: sl<JoinRequestsBloc>()),
            ],
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: FlatHomeView(flat: displayState.flat),
            ),
          );
        }

        if (displayState is FlatPendingRequest) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: _profileAppBar(context),
            body: const PendingRequestView(),
          );
        }

        if (displayState is FlatPendingExit) {
          return PendingExitPage(
            flat: displayState.flat,
            settlement: displayState.settlement,
          );
        }

        if (displayState is FlatExitPendingAck) {
          return ExitSummaryPage(
            settlement: displayState.settlement,
            flatName: displayState.flatName,
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _profileAppBar(context),
          body: const FlatLandingView(),
        );
      },
    );
  }

  PreferredSizeWidget _profileAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline, color: AppColors.textPrimary),
          onPressed: () => context.push(AppRoutes.profile),
        ),
      ],
    );
  }

  FlatState _resolveDisplay(FlatState state) {
    if (state is FlatActionLoading) return state.base;
    if (state is FlatError) return state.fallback;
    return state;
  }

  bool _wasRequest(BuildContext context) => false;
}
