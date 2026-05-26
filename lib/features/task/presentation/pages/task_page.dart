import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../flat/domain/entities/flat_member_entity.dart';
import '../args/task_page_args.dart';
import '../bloc/task_bloc.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_widgets.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key, required this.args});
  final TaskPageArgs args;

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  String? _statusFilter;
  bool _myTasksOnly = false;
  final ScrollController _scroll = ScrollController();
  // Cached last-loaded state so tab/filter switches don't flash a spinner
  TaskListLoaded? _lastLoaded;
  StreamSubscription<ForegroundPushEvent>? _pushSub;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
    // Reload when a task-related push arrives in the foreground
    _pushSub = PushNotificationService.instance.foregroundStream.listen((event) {
      if (event.isTask && mounted) _load();
    });
  }

  @override
  void dispose() {
    _pushSub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _load() {
    context.read<TaskBloc>().add(TasksLoadRequested(
          widget.args.flatId,
          status: _statusFilter,
          assignedTo: _myTasksOnly ? widget.args.myMemberId : null,
        ));
  }

  void _onScroll() {
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 200) return;
    final s = context.read<TaskBloc>().state;
    if (s is! TaskListLoaded || !s.hasMore || s.isLoadingMore) return;
    final page = (s.pagination['page'] as int?) ?? 1;
    context.read<TaskBloc>().add(TasksLoadMoreRequested(
          widget.args.flatId,
          status: _statusFilter,
          assignedTo: _myTasksOnly ? widget.args.myMemberId : null,
          nextPage: page + 1,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.textPrimColor, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Tasks',
            style: AppTypography.headlineMedium
                .copyWith(color: context.textPrimColor)),
      ),
      floatingActionButton: widget.args.canManage
          ? _GradientFab(onPressed: () => _showCreateSheet(context))
          : null,
      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskError) AppSnackbar.error(context, state.message);
          if (state is TaskActionSuccess) {
            AppSnackbar.success(context, state.message);
            _load();
          }
        },
        builder: (context, state) {
          // Update cache whenever fresh data arrives
          if (state is TaskListLoaded) _lastLoaded = state;

          // Resolve the display state: prefer live loaded state, fall back to
          // cached data so that a reload never flashes an empty spinner.
          final displayState = (state is TaskListLoaded)
              ? state
              : _lastLoaded;

          // Only show the full-screen spinner on the very first load (no cache)
          final isFirstLoad = state is TaskListLoading && _lastLoaded == null;

          return RefreshIndicator(
            color: AppColors.brand,
            onRefresh: () async {
              _load();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                // Gradient header stats card
                SliverToBoxAdapter(
                  child: _StatsHeader(state: displayState ?? state),
                ),

                // Subtle refresh indicator at the top when reloading with data
                if (state is TaskListLoading && _lastLoaded != null)
                  const SliverToBoxAdapter(
                    child: LinearProgressIndicator(
                      color: AppColors.brand,
                      backgroundColor: AppColors.transparent,
                    ),
                  ),

                // Filter chips
                SliverToBoxAdapter(
                  child: _Filters(
                    statusFilter: _statusFilter,
                    myTasksOnly: _myTasksOnly,
                    onStatusChanged: (v) {
                      setState(() => _statusFilter = v);
                      _load();
                    },
                    onMyTasksChanged: (v) {
                      setState(() => _myTasksOnly = v);
                      _load();
                    },
                  ),
                ),

                if (isFirstLoad)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.brand),
                    ),
                  )
                else if (displayState != null) ...[
                  if (displayState.tasks.isEmpty)
                    SliverFillRemaining(
                      child: _EmptyState(
                        canManage: widget.args.canManage,
                        onCreate: () => _showCreateSheet(context),
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.pagePadding,
                      ),
                      sliver: SliverList.separated(
                        itemCount: displayState.tasks.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSizing.sm),
                        itemBuilder: (ctx, i) {
                          final task = displayState.tasks[i];
                          return _TaskCardDecorated(
                            task: task,
                            onTap: () => context
                                .push(
                                  AppRoutes.taskDetail,
                                  extra: TaskDetailArgs(
                                    flatId: widget.args.flatId,
                                    task: task,
                                    canManage: widget.args.canManage,
                                    myMemberId: widget.args.myMemberId,
                                    members: widget.args.members,
                                  ),
                                )
                                .then((_) {
                              if (mounted) _load();
                            }),
                          );
                        },
                      ),
                    ),
                    if (displayState.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(AppSizing.md),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSizing.xxl),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusLg),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<TaskBloc>(),
        child: _CreateTaskSheet(
          flatId: widget.args.flatId,
          members: widget.args.members,
        ),
      ),
    );
  }
}

// ── Gradient FAB ──────────────────────────────────────────────────────────────

class _GradientFab extends StatelessWidget {
  const _GradientFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          shape: BoxShape.circle,
          boxShadow: AppColors.shadowMd,
        ),
        child: const Icon(Icons.add_rounded, color: AppColors.white, size: 28),
      ),
    );
  }
}

// ── Stats Header Card ─────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.state});
  final TaskState state;

  @override
  Widget build(BuildContext context) {
    int total = 0;
    int pending = 0;
    int done = 0;

    if (state is TaskListLoaded) {
      final tasks = (state as TaskListLoaded).tasks;
      total = tasks.length;
      pending = tasks.where((t) => t.isPending || t.isInProgress).length;
      done = tasks.where((t) => t.isCompleted).length;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizing.pagePadding, AppSizing.md,
          AppSizing.pagePadding, AppSizing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.lg, vertical: AppSizing.md),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          boxShadow: AppColors.shadowMd,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatPill(label: 'Total', count: total,
                color: AppColors.white.withValues(alpha: 0.25)),
            _StatPill(label: 'Pending', count: pending,
                color: AppColors.warning.withValues(alpha: 0.35)),
            _StatPill(label: 'Done', count: done,
                color: AppColors.success.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizing.md, vertical: AppSizing.sm),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: AppTypography.h3.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelS.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task Card with Left Border ────────────────────────────────────────────────

class _TaskCardDecorated extends StatelessWidget {
  const _TaskCardDecorated({required this.task, required this.onTap});

  final dynamic task;
  final VoidCallback onTap;

  Color _borderColor() {
    if (task.isCompleted) return AppColors.success;
    if (task.isOverdue) return AppColors.error;
    return AppColors.brand;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          boxShadow: AppColors.shadowSm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent border
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _borderColor(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSizing.radiusMd),
                  bottomLeft: Radius.circular(AppSizing.radiusMd),
                ),
              ),
            ),
            Expanded(
              child: TaskCard(task: task, onTap: onTap),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filters ───────────────────────────────────────────────────────────────────

class _Filters extends StatelessWidget {
  const _Filters({
    required this.statusFilter,
    required this.myTasksOnly,
    required this.onStatusChanged,
    required this.onMyTasksChanged,
  });

  final String? statusFilter;
  final bool myTasksOnly;
  final void Function(String?) onStatusChanged;
  final void Function(bool) onMyTasksChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizing.pagePadding, AppSizing.sm, 0, AppSizing.md,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(
              label: 'All',
              selected: statusFilter == null,
              onTap: () => onStatusChanged(null),
            ),
            const SizedBox(width: AppSizing.xs),
            _Chip(
              label: 'Pending',
              selected: statusFilter == 'pending',
              onTap: () => onStatusChanged('pending'),
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSizing.xs),
            _Chip(
              label: 'In Progress',
              selected: statusFilter == 'in_progress',
              onTap: () => onStatusChanged('in_progress'),
              color: AppColors.info,
            ),
            const SizedBox(width: AppSizing.xs),
            _Chip(
              label: 'Completed',
              selected: statusFilter == 'completed',
              onTap: () => onStatusChanged('completed'),
              color: AppColors.success,
            ),
            const SizedBox(width: AppSizing.md),
            _Chip(
              label: 'Mine',
              selected: myTasksOnly,
              onTap: () => onMyTasksChanged(!myTasksOnly),
              icon: Icons.person_outline,
            ),
            const SizedBox(width: AppSizing.pagePadding),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brand;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.1) : context.cardColor,
          borderRadius: BorderRadius.circular(AppSizing.radiusFull),
          border: Border.all(color: selected ? c : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? c : context.textSecColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: selected ? c : context.textSecColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.canManage, required this.onCreate});
  final bool canManage;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 36,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: AppSizing.md),
            Text('All clear!', style: AppTypography.headlineSmall),
            const SizedBox(height: AppSizing.xs),
            Text(
              canManage
                  ? 'Create your first task to get things done'
                  : 'No tasks have been assigned yet',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (canManage) ...[
              const SizedBox(height: AppSizing.lg),
              AppButton(
                label: 'Create Task',
                onPressed: onCreate,
                fullWidth: false,
                icon: const Icon(Icons.add, size: 18, color: AppColors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Create Task Sheet ─────────────────────────────────────────────────────────

class _CreateTaskSheet extends StatefulWidget {
  const _CreateTaskSheet({required this.flatId, required this.members});
  final String flatId;
  final List<FlatMemberEntity> members;

  @override
  State<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<_CreateTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _subCtrl = TextEditingController();
  FlatMemberEntity? _selectedMember;
  DateTime? _dueDate;
  final List<String> _subTasks = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subCtrl.dispose();
    super.dispose();
  }

  void _addSubTask() {
    final t = _subCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _subTasks.add(t);
      _subCtrl.clear();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<TaskBloc>().add(
          TaskCreateRequested(
            flatId: widget.flatId,
            title: _titleCtrl.text.trim(),
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            assignedTo: _selectedMember?.flatMemberId,
            dueDate: _dueDate != null
                ? '${_dueDate!.year}-'
                    '${_dueDate!.month.toString().padLeft(2, '0')}-'
                    '${_dueDate!.day.toString().padLeft(2, '0')}'
                : null,
            subTaskTitles: _subTasks.isEmpty ? null : List.from(_subTasks),
          ),
        );
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.brand),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizing.pagePadding, 0, AppSizing.pagePadding, AppSizing.md + bottom,
      ),
      child: Form(
        key: _formKey,
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
                    borderRadius:
                        BorderRadius.circular(AppSizing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSizing.md),
              Text('New Task', style: AppTypography.headlineSmall),
              const SizedBox(height: AppSizing.md),

              AppTextField(
                controller: _titleCtrl,
                label: 'Title',
                hint: 'What needs to be done?',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: AppSizing.sm),

              AppTextField(
                controller: _descCtrl,
                label: 'Description (optional)',
                hint: 'Add details...',
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSizing.sm),

              Row(
                children: [
                  Expanded(
                    child: TaskAssigneePicker(
                      members: widget.members,
                      selected: _selectedMember,
                      onChanged: (m) => setState(() => _selectedMember = m),
                    ),
                  ),
                  const SizedBox(width: AppSizing.sm),
                  Expanded(
                    child: TaskDueDatePicker(
                      dueDate: _dueDate,
                      onTap: _pickDate,
                      onClear: () => setState(() => _dueDate = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizing.sm),

              _SubTasksInput(
                subTasks: _subTasks,
                controller: _subCtrl,
                onAdd: _addSubTask,
                onRemove: (i) => setState(() => _subTasks.removeAt(i)),
              ),
              const SizedBox(height: AppSizing.md),

              BlocBuilder<TaskBloc, TaskState>(
                builder: (ctx, state) => AppButton(
                  label: 'Create Task',
                  loading: state is TaskActionLoading,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-tasks input (create sheet only) ──────────────────────────────────────

class _SubTasksInput extends StatelessWidget {
  const _SubTasksInput({
    required this.subTasks,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> subTasks;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sub-tasks',
          style: AppTypography.titleMedium.copyWith(
            color: context.textSecColor,
          ),
        ),
        const SizedBox(height: AppSizing.xs),
        ...subTasks.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: AppSizing.xs),
            child: Row(
              children: [
                const Icon(
                  Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: AppColors.brand,
                ),
                const SizedBox(width: AppSizing.sm),
                Expanded(child: Text(e.value, style: AppTypography.bodyMedium)),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: context.textSecColor,
                  ),
                  onPressed: () => onRemove(e.key),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Add a sub-task...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => onAdd(),
                textInputAction: TextInputAction.done,
              ),
            ),
            TextButton(
              onPressed: onAdd,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizing.sm),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
