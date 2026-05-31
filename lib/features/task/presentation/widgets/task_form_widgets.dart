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
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_outline,
              size: 18,
              color: context.textSecColor,
            ),
            const SizedBox(width: AppSizing.xs),
            Expanded(
              child: Text(
                selected?.name ?? 'Assignee',
                style: AppTypography.bodyMedium.copyWith(
                  color: selected != null
                      ? context.textPrimColor
                      : context.textTerColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: context.textSecColor,
                ),
              )
            else
              Icon(
                Icons.expand_more,
                size: 18,
                color: context.textSecColor,
              ),
          ],
        ),
      ),
    );
  }

  void _show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusLg),
        ),
      ),
      builder: (_) =>
          TaskMemberPickerSheet(members: members, onSelected: onChanged),
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
                color: context.borderColor,
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              ),
            ),
          ),
          Text('Assign To', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSizing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: context.surfaceColor,
              child: Icon(
                Icons.person_off_outlined,
                size: 18,
                color: context.textSecColor,
              ),
            ),
            title: Text(
              'Unassigned',
              style: AppTypography.bodyMedium.copyWith(
                color: context.textSecColor,
              ),
            ),
            onTap: () {
              onSelected(null);
              Navigator.pop(context);
            },
          ),
          Divider(height: 1, color: context.dividerColor),
          ...members.map(
            (m) => ListTile(
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
              subtitle: Text(
                _roleLabel(m.role),
                style: AppTypography.labelSmall,
              ),
              onTap: () {
                onSelected(m);
                Navigator.pop(context);
              },
            ),
          ),
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

/// Multi-select assignee picker — used in create/edit task screens.
class TaskMultiAssigneePicker extends StatelessWidget {
  const TaskMultiAssigneePicker({
    super.key,
    required this.members,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<FlatMemberEntity> members;
  final List<String> selectedIds;
  final void Function(List<String>) onChanged;

  @override
  Widget build(BuildContext context) {
    final memberList = members.cast<FlatMemberEntity>().toList();
    final names = selectedIds.map((id) {
      for (final member in memberList) {
        if (member.flatMemberId == id) return member.name;
      }
      return 'Unknown';
    }).toList();

    return GestureDetector(
      onTap: () => _show(context),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizing.inputHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.md,
          vertical: AppSizing.sm,
        ),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.group_outlined,
              size: 18,
              color: context.textSecColor,
            ),
            const SizedBox(width: AppSizing.xs),
            Expanded(
              child: Text(
                names.isEmpty ? 'Assignees' : names.join(', '),
                style: AppTypography.bodyMedium.copyWith(
                  color: names.isNotEmpty
                      ? context.textPrimColor
                      : context.textTerColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selectedIds.isNotEmpty)
              GestureDetector(
                onTap: () => onChanged([]),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: context.textSecColor,
                ),
              )
            else
              Icon(
                Icons.expand_more,
                size: 18,
                color: context.textSecColor,
              ),
          ],
        ),
      ),
    );
  }

  void _show(BuildContext context) {
    final current = List<String>.from(selectedIds);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusLg),
        ),
      ),
      builder: (sheetCtx) => _MultiPickerSheet(
        members: members,
        initial: current,
        onDone: (ids) {
          onChanged(ids);
          Navigator.pop(sheetCtx);
        },
      ),
    );
  }
}

class _MultiPickerSheet extends StatefulWidget {
  const _MultiPickerSheet({
    required this.members,
    required this.initial,
    required this.onDone,
  });
  final List<FlatMemberEntity> members;
  final List<String> initial;
  final void Function(List<String>) onDone;

  @override
  State<_MultiPickerSheet> createState() => _MultiPickerSheetState();
}

class _MultiPickerSheetState extends State<_MultiPickerSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initial);
  }

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
                color: context.borderColor,
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              ),
            ),
          ),
          Text('Assign To', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSizing.sm),
          Text(
            'Select one or more members',
            style: AppTypography.bodySmall.copyWith(
              color: context.textSecColor,
            ),
          ),
          const SizedBox(height: AppSizing.md),
          ...widget.members.map((m) {
            final checked = _selected.contains(m.flatMemberId);
            return CheckboxListTile(
              value: checked,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selected.add(m.flatMemberId);
                } else {
                  _selected.remove(m.flatMemberId);
                }
              }),
              title: Text(m.name, style: AppTypography.bodyMedium),
              subtitle: Text(
                _roleLabel(m.role),
                style: AppTypography.labelSmall.copyWith(
                  color: context.textSecColor,
                ),
              ),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),
          const SizedBox(height: AppSizing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => widget.onDone(_selected.toList()),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSizing.sm + 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
              ),
              child: Text(
                _selected.isEmpty
                    ? 'Clear Assignees'
                    : 'Done (${_selected.length} selected)',
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ),
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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
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
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: context.textSecColor,
            ),
            const SizedBox(width: AppSizing.xs),
            Expanded(
              child: Text(
                dueDate != null ? _format(dueDate!) : 'Due date',
                style: AppTypography.bodyMedium.copyWith(
                  color: dueDate != null
                      ? context.textPrimColor
                      : context.textTerColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (dueDate != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: context.textSecColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
