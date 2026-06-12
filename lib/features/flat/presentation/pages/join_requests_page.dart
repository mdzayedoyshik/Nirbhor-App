import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../bloc/flat_bloc.dart';
import '../bloc/join_requests_bloc.dart';
import '../widgets/join_request_tile.dart';

class JoinRequestsPage extends StatefulWidget {
  final String flatId;

  const JoinRequestsPage({super.key, required this.flatId});

  @override
  State<JoinRequestsPage> createState() => _JoinRequestsPageState();
}

class _JoinRequestsPageState extends State<JoinRequestsPage> {
  @override
  void initState() {
    super.initState();
    context.read<JoinRequestsBloc>().add(JoinRequestsLoadRequested(widget.flatId));
  }

  Future<void> _approve(BuildContext context, String requestId) async {
    // No contribution input — the backend auto-splits the flat's fixed
    // contribution equally across all members on approval.
    final confirmed = await AppDialog.confirm(
      context: context,
      title: AppStrings.approveRequestTitle,
      message: AppStrings.approveRequestMessage,
      confirmLabel: AppStrings.approveLabel,
    );

    if (confirmed != true || !mounted) return;

    // ignore: use_build_context_synchronously
    context.read<JoinRequestsBloc>().add(
      JoinRequestApproveRequested(
        flatId: widget.flatId,
        requestId: requestId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(
          AppStrings.joinRequestsTitle,
          style: AppTypography.titleLarge,
        ),
        backgroundColor: context.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.textPrimColor,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<JoinRequestsBloc, JoinRequestsState>(
        listenWhen: (_, curr) =>
            curr is JoinRequestsActionError || curr is JoinRequestsLoaded,
        listener: (context, state) {
          if (state is JoinRequestsActionError) {
            AppSnackbar.error(context, state.message);
            context.read<JoinRequestsBloc>().add(
              JoinRequestsLoadRequested(widget.flatId),
            );
          }
          if (state is JoinRequestsLoaded) {
            context.read<FlatBloc>().add(FlatRefreshRequested(widget.flatId));
          }
        },
        builder: (context, state) {
          if (state is JoinRequestsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is JoinRequestsLoadError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: AppSizing.iconLg,
                  ),
                  const SizedBox(height: AppSizing.md),
                  Text(state.message, style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSizing.md),
                  TextButton(
                    onPressed: () => context.read<JoinRequestsBloc>().add(
                      JoinRequestsLoadRequested(widget.flatId),
                    ),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            );
          }

          var requests = <dynamic>[];
          String? actionLoadingId;

          if (state is JoinRequestsLoaded) {
            requests = state.requests;
          } else if (state is JoinRequestsActionInProgress) {
            requests = state.requests;
            actionLoadingId = state.requestId;
          } else if (state is JoinRequestsActionError) {
            requests = state.requests;
          }

          if (requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizing.pagePadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mark_email_unread_outlined,
                      color: AppColors.textHint,
                      size: AppSizing.iconXl,
                    ),
                    const SizedBox(height: AppSizing.md),
                    Text(
                      'All Caught Up',
                      style: AppTypography.titleMedium.copyWith(
                        color: context.textPrimColor,
                      ),
                    ),
                    const SizedBox(height: AppSizing.xs),
                    Text(
                      'When someone requests to join your flat, they\'ll appear here.',
                      style: AppTypography.bodySmall.copyWith(
                        color: context.textSecColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizing.pagePadding),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSizing.md),
            itemBuilder: (context, i) {
              final req = requests[i];
              final isLoading = actionLoadingId == req.requestId;

              return JoinRequestTile(
                request: req,
                isLoading: isLoading,
                onApprove: isLoading
                    ? null
                    : () => _approve(context, req.requestId),
                onDecline: isLoading
                    ? null
                    : () => context.read<JoinRequestsBloc>().add(
                        JoinRequestDeclineRequested(
                          flatId: widget.flatId,
                          requestId: req.requestId,
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
