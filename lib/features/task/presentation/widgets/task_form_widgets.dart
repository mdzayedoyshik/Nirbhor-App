import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../flat/domain/entities/flat_member_entity.dart';

/// Reusable assignee picker button used in create + edit sheets.
class TaskAssigneePicker extends StatelessWidget {
  const TaskAssigneePicker({
    super.key,
    required this.members,
    required this.selected,
    required this.onChanged,
  });

  final List<FlatMemberEntity> members;
  final FlatMemberEntity? selected;
  final void Function(FlatMemberEntity?) onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _show(context),
      child: Container(
        height: AppSizing.inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSizing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSizing.xs),
            Expanded(
              child: Text(
                selected?.name ?? 'Assignee',
                style: AppTypography.bodyMedium.copyWith(
                  color: selected != null ? AppColors.textPrimary : AppColors.textHint,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
              )
            else
              const Icon(Icons.expand_more, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizing.radiusLg)),
      ),
      builder: (_) => TaskMemberPickerSheet(members: members, onSelected: onChanged),
    );
  }
}

class TaskMemberPickerSheet extends StatelessWidget {
  const TaskMemberPickerSheet({
    super.key,
    required this.members,
    required this.onSelected,
  });

  final List<FlatMemberEntity> members;
  final void Function(FlatMemberEntity?) onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizing.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: AppSizing.bottomSheetHandleWidth,
              height: AppSizing.bottomSheetHandleHeight,
              margin: const EdgeInsets.only(bottom: AppSizing.md),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              ),
            ),
          ),
          Text('Assign To', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSizing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceVariant,
              child: Icon(Icons.person_off_outlined, size: 18, color: AppColors.textSecondary),
            ),
            title: Text('Unassigned', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
            onTap: () {
              onSelected(null);
              Navigator.pop(context);
            },
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...members.map((m) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(m.name, style: AppTypography.bodyMedium),
            subtitle: Text(_roleLabel(m.role), style: AppTypography.labelSmall),
            onTap: () {
              onSelected(m);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: AppSizing.sm),
        ],
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
    'manager' => 'Manager',
    'co-manager' => 'Co-manager',
    _ => 'Member',
  };
}

/// Reusable due-date picker button used in create + edit sheets.
class TaskDueDatePicker extends StatelessWidget {
  const TaskDueDatePicker({
    super.key,
    required this.dueDate,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? dueDate;
  final VoidCallback onTap;
  final VoidCallback onClear;

  String _format(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSizing.inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSizing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSizing.xs),
            Expanded(
              child: Text(
                dueDate != null ? _format(dueDate!) : 'Due date',
                style: AppTypography.bodyMedium.copyWith(
                  color: dueDate != null ? AppColors.textPrimary : AppColors.textHint,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (dueDate != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
