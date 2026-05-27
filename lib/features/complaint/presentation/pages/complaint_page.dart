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
import '../args/complaint_page_args.dart';
import '../bloc/complaint_bloc.dart';
import '../widgets/complaint_card.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key, required this.args});
  final ComplaintPageArgs args;

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  String? _statusFilter;
  bool _mineOnly = false;
  final ScrollController _scroll = ScrollController();
  // Cached last-loaded state so tab/filter switches don't flash a spinner
  ComplaintListLoaded? _lastLoaded;
  StreamSubscription<ForegroundPushEvent>? _pushSub;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
    // Reload when a complaint-related push arrives in the foreground
    _pushSub = PushNotificationService.instance.foregroundStream.listen((event) {
      if (event.isComplaint && mounted) _load();
    });
  }

  @override
  void dispose() {
    _pushSub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _load() {
    context.read<ComplaintBloc>().add(ComplaintsLoadRequested(
          widget.args.flatId,
          status: _statusFilter,
          raisedBy: _mineOnly ? widget.args.myMemberId : null,
        ));
  }

  void _onScroll() {
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 200) {
      return;
    }
    final s = context.read<ComplaintBloc>().state;
    if (s is! ComplaintListLoaded || !s.hasMore || s.isLoadingMore) return;
    final page = (s.pagination['page'] as int?) ?? 1;
    context.read<ComplaintBloc>().add(ComplaintsLoadMoreRequested(
          widget.args.flatId,
          status: _statusFilter,
          raisedBy: _mineOnly ? widget.args.myMemberId : null,
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
        title: Text('Complaints',
            style: AppTypography.headlineMedium
                .copyWith(color: context.textPrimColor)),
      ),
      floatingActionButton: _GradientFab(
        onPressed: () => _showRaiseSheet(context),
      ),
      body: BlocConsumer<ComplaintBloc, ComplaintState>(
        listener: (context, state) {
          if (state is ComplaintError) {
            AppSnackbar.error(context, state.message);
          }
          if (state is ComplaintActionSuccess) {
            AppSnackbar.success(context, state.message);
            _load();
          }
        },
        builder: (context, state) {
          // Update cache whenever fresh data arrives
          if (state is ComplaintListLoaded) _lastLoaded = state;

          // Resolve the display state: prefer live loaded state, fall back to
          // cached data so that a reload never flashes an empty spinner.
          final displayState = (state is ComplaintListLoaded)
              ? state
              : _lastLoaded;

          // Only show the full-screen spinner on the very first load (no cache)
          final isFirstLoad =
              state is ComplaintListLoading && _lastLoaded == null;

          return RefreshIndicator(
            color: AppColors.brand,
            onRefresh: () async {
              _load();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                // Summary stats strip
                SliverToBoxAdapter(
                  child: _StatsStrip(state: displayState ?? state),
                ),

                // Subtle refresh indicator at the top when reloading with data
                if (state is ComplaintListLoading && _lastLoaded != null)
                  const SliverToBoxAdapter(
                    child: LinearProgressIndicator(
                      color: AppColors.brand,
                      backgroundColor: AppColors.transparent,
                    ),
                  ),

                // Filters
                SliverToBoxAdapter(
                  child: _Filters(
                    statusFilter: _statusFilter,
                    mineOnly: _mineOnly,
                    onStatusChanged: (v) {
                      setState(() => _statusFilter = v);
                      _load();
                    },
                    onMineChanged: (v) {
                      setState(() => _mineOnly = v);
                      _load();
                    },
                  ),
                ),

                if (isFirstLoad)
                  const SliverFillRemaining(
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.brand),
                    ),
                  )
                else if (displayState != null) ...[
                  if (displayState.complaints.isEmpty)
                    SliverFillRemaining(
                      child: _EmptyState(
                        onCreate: () => _showRaiseSheet(context),
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.pagePadding,
                      ),
                      sliver: SliverList.separated(
                        itemCount: displayState.complaints.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSizing.sm),
                        itemBuilder: (ctx, i) {
                          final c = displayState.complaints[i];
                          return ComplaintCard(
                            complaint: c,
                            onTap: () => context
                                .push(
                                  AppRoutes.complaintDetail,
                                  extra: ComplaintDetailArgs(
                                    flatId: widget.args.flatId,
                                    complaint: c,
                                    canManage: widget.args.canManage,
                                    myMemberId: widget.args.myMemberId,
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
                                color: AppColors.brand),
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

  void _showRaiseSheet(BuildContext context) {
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
        value: context.read<ComplaintBloc>(),
        child: _RaiseComplaintSheet(flatId: widget.args.flatId),
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

// ── Stats Strip ───────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.state});
  final ComplaintState state;

  @override
  Widget build(BuildContext context) {
    int open = 0;
    int inProgress = 0;
    int resolved = 0;

    if (state is ComplaintListLoaded) {
      final complaints = (state as ComplaintListLoaded).complaints;
      open = complaints.where((c) => c.isOpen).length;
      inProgress = complaints.where((c) => c.isInProgress).length;
      resolved = complaints.where((c) => c.isResolved).length;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizing.pagePadding, AppSizing.md,
          AppSizing.pagePadding, AppSizing.sm),
      child: Row(
        children: [
          _StatTile(
            label: 'Open',
            count: open,
            background: AppColors.error.withValues(alpha: 0.08),
            textColor: AppColors.error,
            borderColor: AppColors.error.withValues(alpha: 0.2),
          ),
          const SizedBox(width: AppSizing.sm),
          _StatTile(
            label: 'In Progress',
            count: inProgress,
            background: AppColors.warning.withValues(alpha: 0.08),
            textColor: AppColors.warning,
            borderColor: AppColors.warning.withValues(alpha: 0.2),
          ),
          const SizedBox(width: AppSizing.sm),
          _StatTile(
            label: 'Resolved',
            count: resolved,
            background: AppColors.success.withValues(alpha: 0.08),
            textColor: AppColors.success,
            borderColor: AppColors.success.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.count,
    required this.background,
    required this.textColor,
    required this.borderColor,
  });

  final String label;
  final int count;
  final Color background;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.sm, vertical: AppSizing.sm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: AppTypography.h3.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: AppTypography.labelS.copyWith(color: textColor),
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
    required this.mineOnly,
    required this.onStatusChanged,
    required this.onMineChanged,
  });

  final String? statusFilter;
  final bool mineOnly;
  final void Function(String?) onStatusChanged;
  final void Function(bool) onMineChanged;

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
            _Chip(label: 'All', selected: statusFilter == null,
                onTap: () => onStatusChanged(null)),
            const SizedBox(width: AppSizing.xs),
            _Chip(
              label: 'Open',
              selected: statusFilter == 'open',
              onTap: () => onStatusChanged('open'),
              color: AppColors.error,
            ),
            const SizedBox(width: AppSizing.xs),
            _Chip(
              label: 'In Progress',
              selected: statusFilter == 'in_progress',
              onTap: () => onStatusChanged('in_progress'),
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSizing.xs),
            _Chip(
              label: 'Resolved',
              selected: statusFilter == 'resolved',
              onTap: () => onStatusChanged('resolved'),
              color: AppColors.success,
            ),
            const SizedBox(width: AppSizing.md),
            _Chip(
              label: 'Mine',
              selected: mineOnly,
              onTap: () => onMineChanged(!mineOnly),
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
              Icon(icon, size: 13,
                  color: selected ? c : context.textSecColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: selected ? c : context.textSecColor,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w500,
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
  const _EmptyState({required this.onCreate});
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
                color: AppColors.success.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.handshake_outlined,
                size: 36,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSizing.md),
            Text('No complaints — great teamwork!',
                style: AppTypography.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSizing.xs),
            Text(
              'Everything looks good! Raise a complaint if something needs attention.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Raise Complaint Sheet ─────────────────────────────────────────────────────

class _RaiseComplaintSheet extends StatefulWidget {
  const _RaiseComplaintSheet({required this.flatId});
  final String flatId;

  @override
  State<_RaiseComplaintSheet> createState() => _RaiseComplaintSheetState();
}

class _RaiseComplaintSheetState extends State<_RaiseComplaintSheet> {
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ComplaintBloc>().add(ComplaintRaiseRequested(
          flatId: widget.flatId,
          subject: _subjectCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
        ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizing.pagePadding, 0,
        AppSizing.pagePadding, AppSizing.md + bottom,
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
              Text('Raise a Complaint', style: AppTypography.headlineSmall),
              const SizedBox(height: AppSizing.md),
              AppTextField(
                controller: _subjectCtrl,
                label: 'Subject',
                hint: "What's the issue?",
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
              ),
              const SizedBox(height: AppSizing.sm),
              AppTextField(
                controller: _descCtrl,
                label: 'Details (optional)',
                hint: 'Describe the problem in detail...',
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSizing.md),
              BlocBuilder<ComplaintBloc, ComplaintState>(
                builder: (ctx, state) => AppButton(
                  label: 'Submit Complaint',
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
