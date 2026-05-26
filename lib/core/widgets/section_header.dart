import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizing.dart';
import '../constants/app_typography.dart';

/// A section header row with optional eyebrow label and action button.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.actionLabel,
    this.onAction,
  });

  final String title;

  /// Small all-caps overline text shown above the title.
  final String? eyebrow;

  /// Label for the trailing text button.
  final String? actionLabel;

  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      eyebrow!.toUpperCase(),
                      style: AppTypography.overline.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: AppTypography.labelM.copyWith(color: AppColors.brand),
              ),
            ),
        ],
      ),
    );
  }
}
