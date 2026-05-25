import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/task_entity.dart';
import 'task_status_badge.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  final TaskEntity task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.isCompleted;
    final isOverdue = task.isOverdue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(
            color: isOverdue
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: AppTypography.titleMedium.copyWith(
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizing.sm),
                TaskStatusBadge(status: task.status, small: true),
              ],
            ),

            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: AppSizing.xs),
              Text(
                task.description!,
                style: AppTypography.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: AppSizing.sm),

            // Footer row
            Row(
              children: [
                // Assignee
                if (task.assignedToName != null) ...[
                  _AssigneeChip(name: task.assignedToName!),
                  const SizedBox(width: AppSizing.sm),
                ] else ...[
                  _AssigneeChip(name: 'Unassigned', muted: true),
                  const SizedBox(width: AppSizing.sm),
                ],

                const Spacer(),

                // Sub-task count
                if ((task.subTaskCount ?? 0) > 0) ...[
                  _SubTaskProgress(
                    done: task.subTasksCompleted ?? 0,
                    total: task.subTaskCount ?? 0,
                  ),
                  const SizedBox(width: AppSizing.sm),
                ],

                // Due date
                if (task.dueDate != null)
                  _DueChip(dueDate: task.dueDate!, isOverdue: isOverdue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssigneeChip extends StatelessWidget {
  const _AssigneeChip({required this.name, this.muted = false});
  final String name;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!muted)
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          Icon(Icons.person_outline, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          name,
          style: AppTypography.labelSmall.copyWith(
            color: muted ? AppColors.textHint : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SubTaskProgress extends StatelessWidget {
  const _SubTaskProgress({required this.done, required this.total});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : done / total;
    final color = fraction == 1.0 ? AppColors.success : AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizing.radiusFull),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$done/$total',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _DueChip extends StatelessWidget {
  const _DueChip({required this.dueDate, required this.isOverdue});
  final String dueDate;
  final bool isOverdue;

  String _format(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = isOverdue ? AppColors.error : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOverdue ? Icons.warning_amber_rounded : Icons.calendar_today_outlined,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          _format(dueDate),
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
