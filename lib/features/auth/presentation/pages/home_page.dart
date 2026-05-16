import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../features/flat/presentation/bloc/flat_bloc.dart';
import '../../../../features/flat/presentation/cubit/join_requests_cubit.dart';
import '../../../../features/flat/presentation/pages/flat_home_view.dart';
import '../../../../features/flat/presentation/pages/flat_landing_view.dart';
import '../../../../features/flat/presentation/pages/pending_request_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlatBloc, FlatState>(
      listener: (context, state) {
        if (state is FlatError) {
          AppSnackbar.error(context, state.message);
        }
        if (state is FlatNone && _wasRequest(context)) {
          AppSnackbar.success(context, 'Join request cancelled.');
        }
      },
      builder: (context, state) {
        // Resolve display state — look through loading/error wrappers
        final displayState = _resolveDisplay(state);

        // Still doing the initial session check
        if (displayState is FlatChecking || displayState is FlatInitial) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (displayState is FlatLoaded) {
          return BlocProvider(
            create: (_) => sl<JoinRequestsCubit>()..load(displayState.flat.id),
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

        // FlatNone (or unknown) — show landing
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

  bool _wasRequest(BuildContext context) {
    // Check if we just transitioned from FlatPendingRequest — heuristic based
    // on FlatBloc's last known base state in FlatActionLoading
    return false; // Snackbar handled in PendingRequestView already
  }
}
