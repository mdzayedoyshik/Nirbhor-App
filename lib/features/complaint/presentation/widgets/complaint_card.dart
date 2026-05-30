import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/complaint_entity.dart';
import 'complaint_status_badge.dart';

class ComplaintCard extends StatelessWidget {
  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.onTap,
  });

  final ComplaintEntity complaint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Status indicator dot
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: AppSizing.sm, top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _dotColor(complaint.status),
              ),
            ),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint.subject,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: complaint.isResolved
                          ? TextDecoration.lineThrough
                          : null,
                      color: complaint.isResolved
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ComplaintStatusBadge(complaint.status),
                      const SizedBox(width: AppSizing.sm),
                      Expanded(
                        child: Text(
                          'by ${complaint.raisedByName}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (complaint.resolvedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Resolved ${_relativeDate(complaint.resolvedAt!)}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Color _dotColor(String status) => switch (status) {
        'open' => AppColors.warning,
        'in_progress' => const Color(0xFF3B82F6),
        'resolved' => AppColors.success,
        _ => AppColors.textSecondary,
      };

  String _relativeDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'today';
      if (diff.inDays == 1) return 'yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
