import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizing.dart';
import '../constants/app_typography.dart';

/// A 72x72 card with an icon and a label below, used in the quick-action row.
class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// If > 0, a red badge dot is shown on the top-right of the icon.
  final int badge;

  /// Icon tint; defaults to [AppColors.brand].
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.brand;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSizing.r16),
              boxShadow: AppColors.shadowSm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: AppSizing.iconMd, color: effectiveIconColor),
                const SizedBox(height: AppSizing.sp4),
                Text(
                  label,
                  style: AppTypography.labelS.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppSizing.rFull),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
