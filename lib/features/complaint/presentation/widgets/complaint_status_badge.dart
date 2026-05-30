import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class ComplaintStatusBadge extends StatelessWidget {
  const ComplaintStatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status) {
      'open' => (AppColors.warning, Icons.radio_button_unchecked, 'Open'),
      'in_progress' => (
          const Color(0xFF3B82F6),
          Icons.pending_outlined,
          'In Progress'
        ),
      'resolved' => (AppColors.success, Icons.check_circle_outline, 'Resolved'),
      _ => (AppColors.textSecondary, Icons.help_outline, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
