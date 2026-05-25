import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Tasks', style: AppTypography.headlineMedium),
      ),
      floatingActionButton: widget.args.canManage
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _showCreateSheet(context),
              child: const Icon(Icons.add, color: AppColors.white),
            )
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
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              _load();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
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
                if (state is TaskListLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (state is TaskListLoaded) ...[
                  if (state.tasks.isEmpty)
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
                        itemCount: state.tasks.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSizing.sm),
                        itemBuilder: (ctx, i) {
                          final task = state.tasks[i];
                          return TaskCard(
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
                    if (state.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(AppSizing.md),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
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
      backgroundColor: AppColors.surface,
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
              color: const Color(0xFF3B82F6),
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
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusFull),
          border: Border.all(color: selected ? c : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? c : AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: selected ? c : AppColors.textSecondary,
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizing.md),
            Text('No Tasks Yet', style: AppTypography.headlineSmall),
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
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
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
            color: AppColors.textSecondary,
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
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSizing.sm),
                Expanded(child: Text(e.value, style: AppTypography.bodyMedium)),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textSecondary,
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
                foregroundColor: AppColors.primary,
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
