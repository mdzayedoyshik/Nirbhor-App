import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/complaint_entity.dart';
import '../args/complaint_page_args.dart';
import '../bloc/complaint_bloc.dart';
import '../widgets/complaint_status_badge.dart';

class ComplaintDetailPage extends StatefulWidget {
  const ComplaintDetailPage({super.key, required this.args});
  final ComplaintDetailArgs args;

  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<ComplaintBloc>().add(
      ComplaintDetailRequested(widget.args.flatId, widget.args.complaint.id),
    );
  }

  ComplaintEntity? _resolveComplaint(ComplaintState state) {
    if (state is ComplaintDetailLoaded) return state.complaint;
    if (state is ComplaintActionLoading) return state.detail;
    if (state is ComplaintError) return state.detail;
    return widget.args.complaint;
  }

  bool get _isMyComplaint =>
      widget.args.complaint.raisedBy == widget.args.myMemberId;

  void _confirmDelete(BuildContext context, ComplaintEntity c) {
    AppDialog.confirm(
      context: context,
      title: 'Delete Complaint',
      message:
          'Are you sure you want to delete this complaint? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        // ignore: use_build_context_synchronously
        context.read<ComplaintBloc>().add(
          ComplaintDeleteRequested(widget.args.flatId, c.id),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text('Complaint', style: AppTypography.headlineMedium),
        actions: [
          BlocBuilder<ComplaintBloc, ComplaintState>(
            builder: (context, state) {
              final c = _resolveComplaint(state);
              if (c == null) return const SizedBox.shrink();
              final isLoading = state is ComplaintActionLoading;

              // Show menu if: manager OR (own open complaint)
              final canEdit =
                  (widget.args.canManage || _isMyComplaint) && c.isOpen;
              final canDelete = widget.args.canManage && c.isOpen;

              if (!canEdit && !canDelete) return const SizedBox.shrink();
              return IconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.more_vert_rounded),
                onPressed: isLoading
                    ? null
                    : () => _showMenu(context, c, canEdit, canDelete),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ComplaintBloc, ComplaintState>(
        listener: (context, state) {
          if (state is ComplaintError) {
            AppSnackbar.error(context, state.message);
          }
          if (state is ComplaintActionSuccess) {
            AppSnackbar.success(context, state.message);
            if (state.message == 'Complaint deleted') {
              Navigator.pop(context);
            }
          }
        },
        builder: (context, state) {
          if (state is ComplaintDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final c = _resolveComplaint(state);
          if (c == null) {
            return const Center(child: Text('Complaint not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(complaint: c),
                const SizedBox(height: AppSizing.md),
                _InfoCard(complaint: c),
                const SizedBox(height: AppSizing.md),
                if (!c.isResolved)
                  _StatusActions(
                    complaint: c,
                    canManage: widget.args.canManage,
                    flatId: widget.args.flatId,
                  ),
                const SizedBox(height: AppSizing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMenu(
    BuildContext context,
    ComplaintEntity c,
    bool canEdit,
    bool canDelete,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusLg),
        ),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSizing.sm),
            Container(
              width: AppSizing.bottomSheetHandleWidth,
              height: AppSizing.bottomSheetHandleHeight,
              decoration: BoxDecoration(
                color: sheetCtx.borderColor,
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              ),
            ),
            const SizedBox(height: AppSizing.sm),
            if (canEdit)
              ListTile(
                leading: Icon(
                  Icons.edit_outlined,
                  color: sheetCtx.textPrimColor,
                ),
                title: Text('Edit Complaint', style: AppTypography.bodyMedium),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showEditSheet(context, c);
                },
              ),
            if (canDelete)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: Text(
                  'Delete Complaint',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _confirmDelete(context, c);
                },
              ),
            const SizedBox(height: AppSizing.sm),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, ComplaintEntity c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusLg),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ComplaintBloc>(),
        child: _EditComplaintSheet(flatId: widget.args.flatId, complaint: c),
      ),
    );
  }
}

// ── Header Card ───────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.complaint});
  final ComplaintEntity complaint;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ComplaintBloc, ComplaintState>(
      builder: (context, state) {
        final isLoading = state is ComplaintActionLoading;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizing.md),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ComplaintStatusBadge(complaint.status),
                  if (isLoading) ...[
                    const SizedBox(width: AppSizing.sm),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSizing.sm),
              Text(
                complaint.subject,
                style: AppTypography.headlineSmall.copyWith(
                  decoration: complaint.isResolved
                      ? TextDecoration.lineThrough
                      : null,
                  color: complaint.isResolved
                      ? context.textSecColor
                      : context.textPrimColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.complaint});
  final ComplaintEntity complaint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (complaint.description != null &&
              complaint.description!.isNotEmpty) ...[
            Text(
              complaint.description!,
              style: AppTypography.bodyMedium.copyWith(
                color: context.textSecColor,
              ),
            ),
            const SizedBox(height: AppSizing.md),
            Divider(height: 1, color: context.borderColor),
            const SizedBox(height: AppSizing.md),
          ],
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Raised by',
            value: complaint.raisedByName,
          ),
          const SizedBox(height: AppSizing.sm),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Raised on',
            value: _formatDate(complaint.createdAt),
          ),
          if (complaint.resolvedAt != null) ...[
            const SizedBox(height: AppSizing.sm),
            _InfoRow(
              icon: Icons.check_circle_outline,
              label: 'Resolved on',
              value: _formatDate(complaint.resolvedAt!),
              valueColor: AppColors.success,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
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
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.textSecColor),
        const SizedBox(width: AppSizing.sm),
        Text(
          '$label: ',
          style: AppTypography.bodySmall.copyWith(
            color: context.textSecColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? context.textPrimColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Status Actions ─────────────────────────────────────────────────────────────

class _StatusActions extends StatelessWidget {
  const _StatusActions({
    required this.complaint,
    required this.canManage,
    required this.flatId,
  });

  final ComplaintEntity complaint;
  final bool canManage;
  final String flatId;

  @override
  Widget build(BuildContext context) {
    if (!canManage) return const SizedBox.shrink();

    final nextStatus = complaint.isOpen ? 'in_progress' : 'resolved';
    final label = complaint.isOpen ? 'Mark In Progress' : 'Mark Resolved';
    final icon = complaint.isOpen
        ? Icons.play_arrow_rounded
        : Icons.check_circle_outline_rounded;
    final color = complaint.isOpen
        ? const Color(0xFF3B82F6)
        : AppColors.success;

    return BlocBuilder<ComplaintBloc, ComplaintState>(
      builder: (context, state) {
        final isLoading = state is ComplaintActionLoading;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizing.md),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Status',
                style: AppTypography.titleMedium.copyWith(
                  color: context.textSecColor,
                ),
              ),
              const SizedBox(height: AppSizing.sm),
              SizedBox(
                width: double.infinity,
                height: AppSizing.buttonHeight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isLoading
                      ? null
                      : () => context.read<ComplaintBloc>().add(
                          ComplaintStatusUpdateRequested(
                            flatId: flatId,
                            complaintId: complaint.id,
                            status: nextStatus,
                          ),
                        ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Icon(icon, size: 18),
                  label: Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Edit Complaint Sheet ───────────────────────────────────────────────────────

class _EditComplaintSheet extends StatefulWidget {
  const _EditComplaintSheet({required this.flatId, required this.complaint});

  final String flatId;
  final ComplaintEntity complaint;

  @override
  State<_EditComplaintSheet> createState() => _EditComplaintSheetState();
}

class _EditComplaintSheetState extends State<_EditComplaintSheet> {
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _descCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _subjectCtrl = TextEditingController(text: widget.complaint.subject);
    _descCtrl = TextEditingController(text: widget.complaint.description ?? '');
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<ComplaintBloc>().add(
      ComplaintEditRequested(
        flatId: widget.flatId,
        complaintId: widget.complaint.id,
        subject: _subjectCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pop(context);
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
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSizing.md),
              Text('Edit Complaint', style: AppTypography.headlineSmall),
              const SizedBox(height: AppSizing.md),
              AppTextField(
                controller: _subjectCtrl,
                label: 'Subject',
                hint: "What's the issue?",
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Subject is required'
                    : null,
              ),
              const SizedBox(height: AppSizing.sm),
              AppTextField(
                controller: _descCtrl,
                label: 'Details (optional)',
                hint: 'Describe the problem...',
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSizing.md),
              BlocBuilder<ComplaintBloc, ComplaintState>(
                builder: (ctx, state) => AppButton(
                  label: 'Save Changes',
                  loading: state is ComplaintActionLoading,
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
