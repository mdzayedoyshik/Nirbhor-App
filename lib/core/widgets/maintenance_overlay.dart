import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizing.dart';
import '../constants/app_typography.dart';

class MaintenanceOverlay extends StatelessWidget {
  final String title;
  final String message;

  const MaintenanceOverlay({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusXl),
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          AppSizing.pagePadding,
          AppSizing.lg,
          AppSizing.pagePadding,
          AppSizing.lg,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.construction_rounded,
                size: AppSizing.iconLg,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: AppSizing.md),
            Text(
              title,
              style: AppTypography.h3.copyWith(color: context.textPrimColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizing.sm),
            Text(
              message,
              style: AppTypography.bodyM.copyWith(color: context.textSecColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizing.md,
                vertical: AppSizing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: AppSizing.iconSm,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSizing.xs),
                  Text(
                    'Please check back later',
                    style: AppTypography.labelS.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
