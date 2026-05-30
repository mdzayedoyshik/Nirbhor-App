import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../flat/domain/entities/flat_member_entity.dart';
import '../../domain/entities/sub_task_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../args/task_page_args.dart';
import '../bloc/task_bloc.dart';
import '../widgets/task_form_widgets.dart';
import '../widgets/task_status_badge.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({super.key, required this.args});
  final TaskDetailArgs args;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    context.read<TaskBloc>().add(
      TaskDetailRequested(widget.args.flatId, widget.args.task.id),
    );
  }

  TaskEntity _resolveTask(TaskState state) {
    return switch (state) {
      TaskDetailLoaded(task: final t) => t,
      TaskActionLoading(detail: final t) when t != null => t,
      TaskError(detail: final t) when t != null => t,
      _ => widget.args.task,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskError) AppSnackbar.error(context, state.message);
        if (state is TaskActionSuccess && state.message == 'Task deleted') {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final task = _resolveTask(state);
        final isLoading = state is TaskActionLoading;
        final canManage = widget.args.canManage;
        final isAssignee = task.assignedTo == widget.args.myMemberId;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text('Task Detail', style: AppTypography.headlineMedium),
            actions: [
              if (canManage) ...[
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: isLoading || task.isCompleted
                      ? null
                      : () => _showEditSheet(context, task),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  onPressed: isLoading
                      ? null
                      : () => _confirmDelete(context, task),
                ),
              ],
            ],
          ),
          body: state is TaskDetailLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    _reload();
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSizing.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header card
                        _HeaderCard(task: task, isLoading: isLoading),
                        const SizedBox(height: AppSizing.md),

                        // Info card
                        _InfoCard(task: task),
                        const SizedBox(height: AppSizing.md),

                        // Status actions (assignee / manager)
                        if (!task.isCompleted && (isAssignee || canManage))
                          _StatusActions(
                            task: task,
                            canManage: canManage,
                            isLoading: isLoading,
                            onUpdateStatus: (status) {
                              context.read<TaskBloc>().add(
                                TaskUpdateRequested(
                                  flatId: widget.args.flatId,
                                  taskId: task.id,
                                  status: status,
                                ),
                              );
                            },
                          ),

                        // Revert completed (manager only)
                        if (task.isCompleted && canManage) ...[
                          const SizedBox(height: AppSizing.sm),
                          _RevertButton(
                            isLoading: isLoading,
                            onRevert: () {
                              context.read<TaskBloc>().add(
                                TaskUpdateRequested(
                                  flatId: widget.args.flatId,
                                  taskId: task.id,
                                  status: 'in_progress',
                                ),
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: AppSizing.md),

                        // Sub-tasks
                        _SubTasksSection(
                          task: task,
                          canManage: canManage,
                          isAssignee: isAssignee,
                          isLoading: isLoading,
                          flatId: widget.args.flatId,
                        ),

                        const SizedBox(height: AppSizing.xxl),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, TaskEntity task) {
    AppDialog.confirm(
      context: context,
      title: 'Delete Task',
      message:
          'Are you sure you want to delete "${task.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        context.read<TaskBloc>().add(
          TaskDeleteRequested(widget.args.flatId, task.id),
        );
      }
    });
  }

  void _showEditSheet(BuildContext context, TaskEntity task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusLg),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<TaskBloc>(),
        child: _EditTaskSheet(
          flatId: widget.args.flatId,
          task: task,
          members: widget.args.members,
        ),
      ),
    );
  }
}

// ── Header card ───────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.task, required this.isLoading});
  final TaskEntity task;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: AppTypography.headlineSmall.copyWith(
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSizing.sm),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                TaskStatusBadge(status: task.status),
            ],
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: AppSizing.sm),
            Text(
              task.description!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.task});
  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Assigned to',
            value: task.assignedToName ?? 'Unassigned',
            muted: task.assignedToName == null,
          ),
          const _Divider(),
          _InfoRow(
            icon: Icons.add_task_rounded,
            label: 'Created by',
            value: task.createdByName,
          ),
          if (task.dueDate != null) ...[
            const _Divider(),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Due date',
              value: _formatDate(task.dueDate!),
              accent: task.isOverdue ? AppColors.error : null,
              trailing: task.isOverdue
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSizing.radiusFull,
                        ),
                      ),
                      child: Text(
                        'Overdue',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
          if (task.completedAt != null) ...[
            const _Divider(),
            _InfoRow(
              icon: Icons.check_circle_outline_rounded,
              label: 'Completed',
              value: _formatDate(task.completedAt!),
              accent: AppColors.success,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
    this.accent,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool muted;
  final Color? accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizing.xs + 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent ?? AppColors.textSecondary),
          const SizedBox(width: AppSizing.sm),
          SizedBox(
            width: 96,
            child: Text(label, style: AppTypography.labelSmall),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: muted
                    ? AppColors.textHint
                    : accent ?? AppColors.textPrimary,
                fontStyle: muted ? FontStyle.italic : null,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.divider);
}

// ── Status actions ────────────────────────────────────────────────────────────

class _StatusActions extends StatelessWidget {
  const _StatusActions({
    required this.task,
    required this.canManage,
    required this.isLoading,
    required this.onUpdateStatus,
  });

  final TaskEntity task;
  final bool canManage;
  final bool isLoading;
  final void Function(String) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final nextStatus = task.isPending ? 'in_progress' : 'completed';
    final nextLabel = task.isPending ? 'Mark In Progress' : 'Mark Completed';
    final nextIcon = task.isPending
        ? Icons.play_arrow_rounded
        : Icons.check_rounded;
    final nextColor = task.isPending
        ? const Color(0xFF3B82F6)
        : AppColors.success;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => onUpdateStatus(nextStatus),
            icon: Icon(nextIcon, size: 18),
            label: Text(
              nextLabel,
              style: AppTypography.titleMedium.copyWith(color: AppColors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: nextColor,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSizing.sm + 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _RevertButton extends StatelessWidget {
  const _RevertButton({required this.isLoading, required this.onRevert});
  final bool isLoading;
  final VoidCallback onRevert;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onRevert,
        icon: const Icon(Icons.undo_rounded, size: 16),
        label: const Text('Revert to In Progress'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: AppSizing.sm + 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          ),
        ),
      ),
    );
  }
}

// ── Sub-tasks section ─────────────────────────────────────────────────────────

class _SubTasksSection extends StatefulWidget {
  const _SubTasksSection({
    required this.task,
    required this.canManage,
    required this.isAssignee,
    required this.isLoading,
    required this.flatId,
  });

  final TaskEntity task;
  final bool canManage;
  final bool isAssignee;
  final bool isLoading;
  final String flatId;

  @override
  State<_SubTasksSection> createState() => _SubTasksSectionState();
}

class _SubTasksSectionState extends State<_SubTasksSection> {
  final _addCtrl = TextEditingController();
  bool _showAdd = false;

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  bool get canInteract => widget.canManage || widget.isAssignee;

  @override
  Widget build(BuildContext context) {
    final subTasks = widget.task.subTasks ?? [];
    final isLocked = widget.task.isCompleted;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizing.md,
              AppSizing.md,
              AppSizing.sm,
              AppSizing.sm,
            ),
            child: Row(
              children: [
                Text('Sub-tasks', style: AppTypography.titleLarge),
                const Spacer(),
                if (subTasks.isNotEmpty) ...[
                  Text(
                    '${subTasks.where((s) => s.isCompleted).length}/${subTasks.length}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSizing.sm),
                ],
                if (canInteract && !isLocked)
                  IconButton(
                    icon: Icon(
                      _showAdd ? Icons.close : Icons.add,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    onPressed: () => setState(() => _showAdd = !_showAdd),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Progress bar
          if (subTasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizing.md,
                0,
                AppSizing.md,
                AppSizing.sm,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                child: LinearProgressIndicator(
                  value: subTasks.isEmpty
                      ? 0
                      : subTasks.where((s) => s.isCompleted).length /
                            subTasks.length,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  minHeight: 4,
                ),
              ),
            ),

          const Divider(height: 1, color: AppColors.divider),

          // Add input
          if (_showAdd && !isLocked)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizing.md,
                vertical: AppSizing.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSizing.sm),
                  Expanded(
                    child: TextField(
                      controller: _addCtrl,
                      autofocus: true,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'New sub-task...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _submitAdd(),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  TextButton(
                    onPressed: _submitAdd,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.sm,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),

          // Sub-task list
          if (subTasks.isEmpty && !_showAdd)
            Padding(
              padding: const EdgeInsets.all(AppSizing.md),
              child: Text(
                isLocked ? 'No sub-tasks' : 'No sub-tasks yet',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            )
          else
            ...subTasks.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return _SubTaskTile(
                subTask: s,
                canToggle: canInteract && !isLocked,
                canRename: widget.canManage && !isLocked,
                canDelete: widget.canManage && !isLocked,
                isLoading: widget.isLoading,
                onToggle: () {
                  context.read<TaskBloc>().add(
                    SubTaskUpdateRequested(
                      flatId: widget.flatId,
                      taskId: widget.task.id,
                      subTaskId: s.id,
                      isCompleted: !s.isCompleted,
                    ),
                  );
                },
                onRename: () => _showRenameDialog(context, s),
                onDelete: () {
                  context.read<TaskBloc>().add(
                    SubTaskDeleteRequested(
                      flatId: widget.flatId,
                      taskId: widget.task.id,
                      subTaskId: s.id,
                    ),
                  );
                },
                showDivider: i < subTasks.length - 1 || _showAdd,
              );
            }),
        ],
      ),
    );
  }

  void _submitAdd() {
    final t = _addCtrl.text.trim();
    if (t.isEmpty) return;
    context.read<TaskBloc>().add(
      SubTaskAddRequested(
        flatId: widget.flatId,
        taskId: widget.task.id,
        title: t,
      ),
    );
    _addCtrl.clear();
    setState(() => _showAdd = false);
  }

  void _showRenameDialog(BuildContext context, SubTaskEntity s) {
    final ctrl = TextEditingController(text: s.title);
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        ),
        title: Text('Rename Sub-task', style: AppTypography.headlineSmall),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Sub-task title',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.isEmpty) return;
              context.read<TaskBloc>().add(
                SubTaskUpdateRequested(
                  flatId: widget.flatId,
                  taskId: widget.task.id,
                  subTaskId: s.id,
                  title: t,
                ),
              );
              Navigator.pop(dCtx);
            },
            child: Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _SubTaskTile extends StatelessWidget {
  const _SubTaskTile({
    required this.subTask,
    required this.canToggle,
    required this.canRename,
    required this.canDelete,
    required this.isLoading,
    required this.onToggle,
    required this.onRename,
    required this.onDelete,
    required this.showDivider,
  });

  final SubTaskEntity subTask;
  final bool canToggle;
  final bool canRename;
  final bool canDelete;
  final bool isLoading;
  final VoidCallback onToggle;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.md,
            vertical: AppSizing.xs + 2,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: canToggle && !isLoading ? onToggle : null,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    subTask.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    key: ValueKey(subTask.isCompleted),
                    size: 22,
                    color: subTask.isCompleted
                        ? AppColors.success
                        : AppColors.border,
                  ),
                ),
              ),
              const SizedBox(width: AppSizing.sm),
              Expanded(
                child: GestureDetector(
                  onLongPress: canRename ? onRename : null,
                  child: Text(
                    subTask.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: subTask.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: subTask.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              ),
              if (canDelete)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                  onPressed: isLoading ? null : onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

// ── Edit Task Sheet ───────────────────────────────────────────────────────────

class _EditTaskSheet extends StatefulWidget {
  const _EditTaskSheet({
    required this.flatId,
    required this.task,
    required this.members,
  });
  final String flatId;
  final TaskEntity task;
  final List<FlatMemberEntity> members;

  @override
  State<_EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<_EditTaskSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  FlatMemberEntity? _selectedMember;
  DateTime? _dueDate;
  bool _clearAssignee = false;
  bool _clearDueDate = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description ?? '');
    // Resolve current assignee
    if (widget.task.assignedTo != null) {
      try {
        _selectedMember = widget.members.firstWhere(
          (m) => m.flatMemberId == widget.task.assignedTo,
        );
      } catch (_) {}
    }
    // Resolve current due date
    if (widget.task.dueDate != null) {
      try {
        _dueDate = DateTime.parse(widget.task.dueDate!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final dueStr = _dueDate != null && !_clearDueDate
        ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
        : null;
    FocusScope.of(context).unfocus();
    context.read<TaskBloc>().add(
      TaskUpdateRequested(
        flatId: widget.flatId,
        taskId: widget.task.id,
        title: title != widget.task.title ? title : null,
        description: _descCtrl.text.trim() != (widget.task.description ?? '')
            ? _descCtrl.text.trim()
            : null,
        assignedTo: _clearAssignee ? null : _selectedMember?.flatMemberId,
        clearAssignee: _clearAssignee,
        dueDate: _clearDueDate ? null : dueStr,
        clearDueDate: _clearDueDate,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pop(context);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null)
      setState(() {
        _dueDate = picked;
        _clearDueDate = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizing.pagePadding,
        0,
        AppSizing.pagePadding,
        AppSizing.md + bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizing.sm),
            Center(
              child: Container(
                width: AppSizing.bottomSheetHandleWidth,
                height: AppSizing.bottomSheetHandleHeight,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSizing.md),
            Text('Edit Task', style: AppTypography.headlineSmall),
            const SizedBox(height: AppSizing.md),

            AppTextField(controller: _titleCtrl, label: 'Title'),
            const SizedBox(height: AppSizing.sm),
            AppTextField(
              controller: _descCtrl,
              label: 'Description (optional)',
              maxLines: 3,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: AppSizing.sm),

            Row(
              children: [
                Expanded(
                  child: TaskAssigneePicker(
                    members: widget.members,
                    selected: _clearAssignee ? null : _selectedMember,
                    onChanged: (m) => setState(() {
                      _selectedMember = m;
                      _clearAssignee =
                          m == null && widget.task.assignedTo != null;
                    }),
                  ),
                ),
                const SizedBox(width: AppSizing.sm),
                Expanded(
                  child: TaskDueDatePicker(
                    dueDate: _clearDueDate ? null : _dueDate,
                    onTap: _pickDate,
                    onClear: () => setState(() {
                      _dueDate = null;
                      _clearDueDate = true;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizing.md),

            BlocBuilder<TaskBloc, TaskState>(
              builder: (ctx, state) => AppButton(
                label: 'Save Changes',
                loading: state is TaskActionLoading,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
