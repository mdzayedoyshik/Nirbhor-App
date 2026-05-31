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
      child: Dialog.fullscreen(
        backgroundColor: context.bgColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizing.pagePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    size: AppSizing.iconXl,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: AppSizing.lg),
                Text(
                  title,
                  style: AppTypography.h1.copyWith(color: context.textPrimColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizing.sm),
                Text(
                  message,
                  style: AppTypography.bodyM.copyWith(color: context.textSecColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizing.xl),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.md,
                    vertical: AppSizing.sm,
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
        ),
      ),
    );
  }
}
