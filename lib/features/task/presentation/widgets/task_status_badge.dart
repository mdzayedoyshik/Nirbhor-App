import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';

class TaskStatusBadge extends StatelessWidget {
  const TaskStatusBadge({super.key, required this.status, this.small = false});

  final String status;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'in_progress' => ('In Progress', const Color(0xFF3B82F6), Icons.play_circle_outline_rounded),
      'completed'   => ('Completed',   AppColors.success,        Icons.check_circle_outline_rounded),
      _             => ('Pending',     AppColors.warning,        Icons.radio_button_unchecked_rounded),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : AppSizing.sm,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 11 : 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: (small ? AppTypography.labelSmall : AppTypography.labelSmall).copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: small ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}
