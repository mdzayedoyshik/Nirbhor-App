import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../bloc/flat_bloc.dart';

class PendingRequestView extends StatelessWidget {
  const PendingRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlatBloc, FlatState>(
      listener: (context, state) {
        if (state is FlatError) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final request = switch (state) {
          FlatPendingRequest s => s.request,
          FlatActionLoading s when s.base is FlatPendingRequest =>
            (s.base as FlatPendingRequest).request,
          FlatError s when s.fallback is FlatPendingRequest =>
            (s.fallback as FlatPendingRequest).request,
          _ => null,
        };

        final isCancelling =
            state is FlatActionLoading &&
            state.source == FlatLoadingSource.cancelRequest;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.pagePadding,
            ),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    size: 52,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: AppSizing.lg),
                Text(
                  AppStrings.pendingRequestTitle,
                  style: AppTypography.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizing.sm),
                Text(
                  AppStrings.pendingRequestSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.textSecColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (request?.flatName != null) ...[
                  const SizedBox(height: AppSizing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizing.md,
                      vertical: AppSizing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.apartment_rounded,
                          size: AppSizing.iconSm,
                          color: context.textSecColor,
                        ),
                        const SizedBox(width: AppSizing.xs),
                        Text(
                          request!.flatName!,
                          style: AppTypography.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(flex: 3),
                AppButton(
                  label: AppStrings.cancelRequestLabel,
                  variant: AppButtonVariant.outlined,
                  loading: isCancelling,
                  onPressed: isCancelling
                      ? null
                      : () => _confirmCancel(context, request?.requestId),
                ),
                const SizedBox(height: AppSizing.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmCancel(BuildContext context, String? requestId) async {
    if (requestId == null) return;
    final confirmed = await AppDialog.confirm(
      context: context,
      title: AppStrings.cancelRequestConfirmTitle,
      message: AppStrings.cancelRequestConfirmMsg,
      confirmLabel: AppStrings.cancelRequestLabel,
      destructive: true,
    );
    if (confirmed == true && context.mounted) {
      context.read<FlatBloc>().add(FlatCancelRequestRequested(requestId));
    }
  }
}
