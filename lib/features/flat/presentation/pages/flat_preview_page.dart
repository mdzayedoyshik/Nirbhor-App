import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/flat_preview_entity.dart';
import '../bloc/flat_bloc.dart';

class FlatPreviewPage extends StatelessWidget {
  final FlatPreviewEntity preview;

  const FlatPreviewPage({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlatBloc, FlatState>(
      listener: (context, state) {
        if (state is FlatPendingRequest) {
          AppSnackbar.success(context, AppStrings.joinRequestSentMsg);
          context.go(AppRoutes.home);
        } else if (state is FlatError) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading =
            state is FlatActionLoading &&
            state.source == FlatLoadingSource.join;

        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            title: Text('Flat Preview', style: AppTypography.titleLarge),
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
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSizing.lg),
                  // Flat avatar
                  AppAvatar(
                    imageUrl: preview.photoUrl,
                    name: preview.flatName,
                    radius: 48,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    textColor: AppColors.primary,
                  ),
                  const SizedBox(height: AppSizing.md),
                  Text(
                    preview.flatName,
                    style: AppTypography.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (preview.address != null) ...[
                    const SizedBox(height: AppSizing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: AppSizing.iconSm,
                          color: context.textSecColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            preview.address!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: context.textSecColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSizing.xl),
                  // Stats row
                  Container(
                    padding: const EdgeInsets.all(AppSizing.md),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.group_outlined,
                          color: AppColors.primary,
                          size: AppSizing.iconMd,
                        ),
                        const SizedBox(width: AppSizing.sm),
                        Text(
                          '${preview.memberCount} ${AppStrings.memberCount}',
                          style: AppTypography.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizing.xl),
                  // Status-based action
                  _buildAction(context, isLoading),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAction(BuildContext context, bool isLoading) {
    if (preview.isActiveMember) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSizing.sm),
                Text(
                  AppStrings.alreadyMember,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizing.md),
          AppButton(
            label: 'Go to Home',
            variant: AppButtonVariant.outlined,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      );
    }

    if (preview.isPending) {
      return Container(
        padding: const EdgeInsets.all(AppSizing.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top_rounded, color: AppColors.warning),
            const SizedBox(width: AppSizing.sm),
            Text(
              AppStrings.requestPending,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      );
    }

    // not_member — show join button
    return AppButton(
      label: AppStrings.sendJoinRequestLabel,
      loading: isLoading,
      onPressed: isLoading
          ? null
          : () =>
                context.read<FlatBloc>().add(FlatJoinRequested(preview.joinCode)),
      icon: const Icon(Icons.send_outlined, color: AppColors.white),
    );
  }
}
