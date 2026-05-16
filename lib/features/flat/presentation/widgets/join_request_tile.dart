import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/join_request_entity.dart';

class JoinRequestTile extends StatelessWidget {
  final JoinRequestEntity request;
  final bool isLoading;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  const JoinRequestTile({
    super.key,
    required this.request,
    this.isLoading = false,
    this.onApprove,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: request.userName ?? 'U', radius: 20),
              const SizedBox(width: AppSizing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.userName ?? 'Unknown',
                      style: AppTypography.titleMedium,
                    ),
                    if (request.userEmail != null)
                      Text(
                        request.userEmail!,
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                _timeAgo(request.requestedAt),
                style: AppTypography.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSizing.md),
          if (isLoading)
            const Center(
              child: SizedBox(
                width: AppSizing.spinnerSize,
                height: AppSizing.spinnerSize,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizing.borderWidthLg,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: AppStrings.declineLabel,
                    variant: AppButtonVariant.outlined,
                    height: AppSizing.buttonHeightSm,
                    onPressed: onDecline,
                  ),
                ),
                const SizedBox(width: AppSizing.sm),
                Expanded(
                  child: AppButton(
                    label: AppStrings.approveLabel,
                    height: AppSizing.buttonHeightSm,
                    onPressed: onApprove,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _timeAgo(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
