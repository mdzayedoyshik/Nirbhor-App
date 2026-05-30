import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../args/task_page_args.dart';
import '../bloc/task_bloc.dart';
import '../widgets/task_form_widgets.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key, required this.args});
  final CreateTaskArgs args;

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _subCtrl = TextEditingController();
  final List<String> _selectedMemberIds = [];
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
            flatId: widget.args.flatId,
            title: _titleCtrl.text.trim(),
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            assignedToIds:
                _selectedMemberIds.isEmpty ? null : List.from(_selectedMemberIds),
            dueDate: _dueDate != null
                ? '${_dueDate!.year}-'
                    '${_dueDate!.month.toString().padLeft(2, '0')}-'
                    '${_dueDate!.day.toString().padLeft(2, '0')}'
                : null,
            subTaskTitles: _subTasks.isEmpty ? null : List.from(_subTasks),
          ),
        );
    Navigator.of(context).pop();
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
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskError) {
          AppSnackbar.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          backgroundColor: context.bgColor,
          elevation: 0,
          title: Text('New Task', style: AppTypography.headlineMedium),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSizing.pagePadding,
              AppSizing.md,
              AppSizing.pagePadding,
              MediaQuery.of(context).viewInsets.bottom + AppSizing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                TaskMultiAssigneePicker(
                  members: widget.args.members,
                  selectedIds: _selectedMemberIds,
                  onChanged: (ids) => setState(() {
                    _selectedMemberIds
                      ..clear()
                      ..addAll(ids);
                  }),
                ),
                const SizedBox(height: AppSizing.sm),
                TaskDueDatePicker(
                  dueDate: _dueDate,
                  onTap: _pickDate,
                  onClear: () => setState(() => _dueDate = null),
                ),
                const SizedBox(height: AppSizing.sm),

                _SubTasksInput(
                  subTasks: _subTasks,
                  controller: _subCtrl,
                  onAdd: _addSubTask,
                  onRemove: (i) => setState(() => _subTasks.removeAt(i)),
                ),
                const SizedBox(height: AppSizing.lg),

                BlocBuilder<TaskBloc, TaskState>(
                  builder: (ctx, state) => AppButton(
                    label: 'Create Task',
                    loading: state is TaskActionLoading,
                    onPressed: _submit,
                    fullWidth: true,
                    variant: AppButtonVariant.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-tasks input ───────────────────────────────────────────────────────────

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
                  color: AppColors.textHint,
                ),
                const SizedBox(width: AppSizing.xs),
                Expanded(
                  child: Text(e.value, style: AppTypography.bodyMedium),
                ),
                GestureDetector(
                  onTap: () => onRemove(e.key),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizing.xs),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Add a sub-task…',
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
                padding: const EdgeInsets.symmetric(horizontal: AppSizing.sm),
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
