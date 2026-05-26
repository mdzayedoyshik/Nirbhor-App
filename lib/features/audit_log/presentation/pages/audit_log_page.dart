import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../args/audit_log_page_args.dart';
import '../bloc/audit_log_bloc.dart';
import '../bloc/audit_log_event.dart';
import '../bloc/audit_log_state.dart';

// ── Action constants ──────────────────────────────────────────────────────────

const _kAllActions = [
  'COMPLAINT_DELETED',
  'COMPLAINT_EDITED',
  'COMPLAINT_RAISED',
  'COMPLAINT_STATUS_UPDATED',
  'EXIT_FINALISED',
  'EXPENSE_APPROVED',
  'FIXED_CONTRIBUTION_AUTO_DEDUCTED',
  'FLAT_CREATED',
  'FLAT_DELETED',
  'FLAT_UPDATED',
  'MANAGER_TRANSFERRED',
  'MEAL_CONFIG_UPDATED',
  'MEAL_LOG_EDITED',
  'MONTH_CLOSED',
  'PAYMENT_VERIFIED',
  'TASK_CREATED',
  'TASK_DELETED',
  'TASK_UPDATED',
];

const _kAllEntityTypes = [
  'complaint',
  'expense',
  'flat',
  'meal',
  'member',
  'month',
  'payment',
  'task',
  'transaction',
];

// ── Filter chip categories ────────────────────────────────────────────────────

const _kFilterChips = [
  _ChipDef(label: 'All', entityType: null),
  _ChipDef(label: 'Members', entityType: 'flat_member'),
  _ChipDef(label: 'Payments', entityType: 'payment'),
  _ChipDef(label: 'Meals', entityType: 'meal_log'),
  _ChipDef(label: 'Expenses', entityType: 'expense'),
  _ChipDef(label: 'Tasks', entityType: 'task'),
];

class _ChipDef {
  final String label;
  final String? entityType;
  const _ChipDef({required this.label, required this.entityType});
}

// ── Label mapping ─────────────────────────────────────────────────────────────

String _actionLabel(String action) {
  switch (action) {
    case 'COMPLAINT_DELETED':
      return 'Complaint Deleted';
    case 'COMPLAINT_EDITED':
      return 'Complaint Edited';
    case 'COMPLAINT_RAISED':
      return 'Complaint Raised';
    case 'COMPLAINT_STATUS_UPDATED':
      return 'Complaint Status Updated';
    case 'EXIT_FINALISED':
      return 'Member Exit Finalised';
    case 'EXPENSE_APPROVED':
      return 'Expense Approved';
    case 'FIXED_CONTRIBUTION_AUTO_DEDUCTED':
      return 'Fixed Contribution Deducted';
    case 'FLAT_CREATED':
      return 'Flat Created';
    case 'FLAT_DELETED':
      return 'Flat Deleted';
    case 'FLAT_UPDATED':
      return 'Flat Updated';
    case 'MANAGER_TRANSFERRED':
      return 'Manager Transferred';
    case 'MEAL_CONFIG_UPDATED':
      return 'Meal Config Updated';
    case 'MEAL_LOG_EDITED':
      return 'Meal Log Edited';
    case 'MONTH_CLOSED':
      return 'Month Closed';
    case 'PAYMENT_VERIFIED':
      return 'Payment Verified';
    case 'TASK_CREATED':
      return 'Task Created';
    case 'TASK_DELETED':
      return 'Task Deleted';
    case 'TASK_UPDATED':
      return 'Task Updated';
    default:
      return action.replaceAll('_', ' ').toLowerCase().replaceFirstMapped(
            RegExp(r'^\w'),
            (m) => m.group(0)!.toUpperCase(),
          );
  }
}

// ── Category helpers ──────────────────────────────────────────────────────────

Color _categoryColor(String action) {
  if (action.startsWith('FLAT_') || action == 'MANAGER_TRANSFERRED') {
    return AppColors.brand;
  }
  if (action.startsWith('COMPLAINT_') || action == 'EXIT_FINALISED') {
    return AppColors.error;
  }
  if (action.startsWith('TASK_')) return AppColors.info;
  if (action == 'PAYMENT_VERIFIED' ||
      action == 'EXPENSE_APPROVED' ||
      action == 'FIXED_CONTRIBUTION_AUTO_DEDUCTED' ||
      action == 'MONTH_CLOSED') {
    return AppColors.success;
  }
  if (action.startsWith('MEAL_')) return AppColors.warning;
  return AppColors.textSecondary;
}

IconData _categoryIcon(String action) {
  if (action.startsWith('FLAT_')) return Icons.home_outlined;
  if (action.startsWith('COMPLAINT_')) return Icons.report_problem_outlined;
  if (action.startsWith('TASK_')) return Icons.task_alt;
  if (action == 'PAYMENT_VERIFIED' ||
      action == 'EXPENSE_APPROVED' ||
      action == 'FIXED_CONTRIBUTION_AUTO_DEDUCTED' ||
      action == 'MONTH_CLOSED') {
    return Icons.account_balance_wallet_outlined;
  }
  if (action.startsWith('MEAL_')) return Icons.restaurant_outlined;
  if (action == 'EXIT_FINALISED' || action == 'MANAGER_TRANSFERRED') {
    return Icons.people_outline;
  }
  return Icons.history;
}

// ── Time helpers ──────────────────────────────────────────────────────────────

String _timeAgo(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal() ?? DateTime.now();
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}

String _timeOnly(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal() ?? DateTime.now();
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _dateGroupLabel(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal() ?? DateTime.now();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(dt.year, dt.month, dt.day);
  if (d == today) return 'Today';
  if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return '${dt.day} ${_monthName(dt.month)} ${dt.year}';
}

String _monthName(int m) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return names[m - 1];
}

String _isoDateOnly(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal() ?? DateTime.now();
  return '${dt.year}-${dt.month}-${dt.day}';
}

// ── Page ──────────────────────────────────────────────────────────────────────

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key, required this.args});

  final AuditLogPageArgs args;

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AuditLogBloc>().add(const AuditLogLoadMoreRequested());
    }
  }

  void _openFilterSheet(BuildContext context, AuditLogFilters current) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusLg),
        ),
      ),
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<AuditLogBloc>(),
        child: _FilterSheet(
          flatId: widget.args.flatId,
          currentFilters: current,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: context.textPrimColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Audit Log',
          style: AppTypography.h3.copyWith(color: context.textPrimColor),
        ),
        actions: [
          BlocBuilder<AuditLogBloc, AuditLogState>(
            builder: (context, state) {
              final filters = state is AuditLogLoaded
                  ? state.filters
                  : const AuditLogFilters();
              final hasActive =
                  filters.action != null || filters.entityType != null;
              return IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: hasActive ? AppColors.brand : context.textSecColor,
                ),
                tooltip: 'Filter',
                onPressed: () => _openFilterSheet(context, filters),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<AuditLogBloc, AuditLogState>(
        listener: (context, state) {
          if (state is AuditLogError) {
            AppSnackbar.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is AuditLogLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            );
          }

          final logs = switch (state) {
            AuditLogLoaded(logs: final l) => l,
            AuditLogError(logs: final l) => l ?? <AuditLogEntity>[],
            _ => <AuditLogEntity>[],
          };

          final filters = state is AuditLogLoaded
              ? state.filters
              : const AuditLogFilters();

          final isLoadingMore =
              state is AuditLogLoaded ? state.isLoadingMore : false;

          final hasActiveFilter =
              filters.action != null || filters.entityType != null;

          return Column(
            children: [
              // ── Filter chip row ───────────────────────────────────────────
              _FilterChipRow(
                filters: filters,
                flatId: widget.args.flatId,
              ),

              // ── Active action filter chip ─────────────────────────────────
              if (hasActiveFilter && filters.action != null)
                Container(
                  width: double.infinity,
                  color: context.cardColor,
                  padding: const EdgeInsets.only(
                    left: AppSizing.pagePadding,
                    right: AppSizing.pagePadding,
                    bottom: AppSizing.sm,
                  ),
                  child: Wrap(
                    spacing: AppSizing.xs,
                    children: [
                      Chip(
                        label: Text(
                          _actionLabel(filters.action!),
                          style: AppTypography.labelS.copyWith(
                            color: AppColors.brand,
                          ),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        deleteIconColor: AppColors.brand,
                        onDeleted: () {
                          context.read<AuditLogBloc>().add(
                                AuditLogFilterChanged(
                                  flatId: widget.args.flatId,
                                  filters: filters.copyWith(action: null),
                                ),
                              );
                        },
                        backgroundColor:
                            AppColors.brand.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ],
                  ),
                ),

              // ── List ──────────────────────────────────────────────────────
              Expanded(
                child: logs.isEmpty
                    ? RefreshIndicator(
                        color: AppColors.brand,
                        onRefresh: () async {
                          context.read<AuditLogBloc>().add(
                                AuditLogLoadRequested(
                                  flatId: widget.args.flatId,
                                  filters: filters,
                                ),
                              );
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.25,
                            ),
                            _EmptyState(),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.brand,
                        onRefresh: () async {
                          context.read<AuditLogBloc>().add(
                                AuditLogLoadRequested(
                                  flatId: widget.args.flatId,
                                  filters: filters,
                                ),
                              );
                        },
                        child: _TimelineList(
                          logs: logs,
                          isLoadingMore: isLoadingMore,
                          scrollController: _scrollController,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Filter Chip Row ───────────────────────────────────────────────────────────

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.filters,
    required this.flatId,
  });

  final AuditLogFilters filters;
  final String flatId;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.cardColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.pagePadding,
        vertical: AppSizing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _kFilterChips.map((chip) {
            final isActive = chip.entityType == null
                ? filters.entityType == null
                : filters.entityType == chip.entityType;
            return Padding(
              padding: const EdgeInsets.only(right: AppSizing.xs),
              child: _PillChip(
                label: chip.label,
                isActive: isActive,
                onTap: () {
                  context.read<AuditLogBloc>().add(
                        AuditLogFilterChanged(
                          flatId: flatId,
                          filters: filters.copyWith(
                            entityType: chip.entityType,
                          ),
                        ),
                      );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.brand
              : AppColors.surface200,
          borderRadius: BorderRadius.circular(AppSizing.rFull),
        ),
        child: Text(
          label,
          style: AppTypography.labelM.copyWith(
            color: isActive ? AppColors.white : context.textSecColor,
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 36,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: AppSizing.md),
          Text(
            'No activity yet',
            style: AppTypography.h4.copyWith(color: context.textPrimColor),
          ),
          const SizedBox(height: AppSizing.xs),
          Text(
            'Actions taken in this flat will appear here',
            style: AppTypography.bodyS.copyWith(
              color: context.textSecColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline List ─────────────────────────────────────────────────────────────

class _TimelineList extends StatelessWidget {
  const _TimelineList({
    required this.logs,
    required this.isLoadingMore,
    required this.scrollController,
  });

  final List<AuditLogEntity> logs;
  final bool isLoadingMore;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    // Build a flat list of items (date headers + log entries)
    final items = <_TimelineItem>[];
    String? lastDate;

    for (final log in logs) {
      final dateKey = _isoDateOnly(log.createdAt);
      if (dateKey != lastDate) {
        lastDate = dateKey;
        items.add(_TimelineItem.header(_dateGroupLabel(log.createdAt)));
      }
      items.add(_TimelineItem.entry(log));
    }

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        top: AppSizing.sm,
        bottom: AppSizing.xl,
        left: AppSizing.pagePadding,
        right: AppSizing.pagePadding,
      ),
      itemCount: items.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizing.md),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.brand,
                strokeWidth: 2,
              ),
            ),
          );
        }
        final item = items[index];
        if (item.isHeader) {
          return _DateHeader(label: item.headerLabel!);
        }
        // Determine if this is the last item in its group (for timeline line)
        final isLast = index == items.length - 1 ||
            items[index + 1].isHeader;
        return _TimelineTile(
          log: item.log!,
          isLast: isLast,
        );
      },
    );
  }
}

class _TimelineItem {
  final bool isHeader;
  final String? headerLabel;
  final AuditLogEntity? log;

  const _TimelineItem._({this.isHeader = false, this.headerLabel, this.log});

  factory _TimelineItem.header(String label) =>
      _TimelineItem._(isHeader: true, headerLabel: label);

  factory _TimelineItem.entry(AuditLogEntity log) =>
      _TimelineItem._(log: log);
}

// ── Date Header ───────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizing.md, bottom: AppSizing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.overline.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSizing.sm),
          Expanded(
            child: Divider(
              color: AppColors.surface300,
              thickness: 1,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline Tile ─────────────────────────────────────────────────────────────

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.log, required this.isLast});

  final AuditLogEntity log;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(log.action);
    final icon = _categoryIcon(log.action);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline spine ──────────────────────────────────────────────
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                // Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.surface300,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: AppSizing.sm),

          // ── Card ────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSizing.sm),
              child: _LogCard(log: log, color: color, icon: icon),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Log Card ──────────────────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  const _LogCard({
    required this.log,
    required this.color,
    required this.icon,
  });

  final AuditLogEntity log;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final hasOld = log.oldValue != null && log.oldValue!.isNotEmpty;
    final hasNew = log.newValue != null && log.newValue!.isNotEmpty;
    final hasDetails = hasOld || hasNew;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        boxShadow: AppColors.shadowSm,
      ),
      child: hasDetails
          ? ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: AppSizing.md,
                vertical: AppSizing.xs,
              ),
              childrenPadding: const EdgeInsets.only(
                left: AppSizing.md,
                right: AppSizing.md,
                bottom: AppSizing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              title: Text(
                _actionLabel(log.action),
                style: AppTypography.labelL.copyWith(
                  color: context.textPrimColor,
                ),
              ),
              subtitle: _LogSubtitle(log: log),
              children: [_ExpandedContent(log: log)],
            )
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizing.md,
                vertical: AppSizing.sm + 2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: AppSizing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _actionLabel(log.action),
                          style: AppTypography.labelL.copyWith(
                            color: context.textPrimColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _LogSubtitle(log: log),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _LogSubtitle extends StatelessWidget {
  const _LogSubtitle({required this.log});

  final AuditLogEntity log;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              log.performedByName ?? 'System',
              style: AppTypography.bodyS.copyWith(
                color: context.textSecColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _timeOnly(log.createdAt),
            style: AppTypography.labelS.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSizing.xs),
          Text(
            _timeAgo(log.createdAt),
            style: AppTypography.labelS.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Expanded Content ──────────────────────────────────────────────────────────

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({required this.log});

  final AuditLogEntity log;

  @override
  Widget build(BuildContext context) {
    final hasOld = log.oldValue != null && log.oldValue!.isNotEmpty;
    final hasNew = log.newValue != null && log.newValue!.isNotEmpty;

    if (!hasOld && !hasNew) {
      return Text(
        'No details available',
        style: AppTypography.bodyS.copyWith(
          color: context.textSecColor,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: AppColors.border, height: 1),
        const SizedBox(height: AppSizing.sm),
        if (hasOld) ...[
          Text(
            'Before',
            style: AppTypography.labelS.copyWith(
              color: context.textSecColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizing.xs),
          _JsonTable(data: log.oldValue!),
          const SizedBox(height: AppSizing.sm),
        ],
        if (hasNew) ...[
          Text(
            'After',
            style: AppTypography.labelS.copyWith(
              color: context.textSecColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizing.xs),
          _JsonTable(data: log.newValue!),
        ],
      ],
    );
  }
}

class _JsonTable extends StatelessWidget {
  const _JsonTable({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface100,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}: ',
                  style: AppTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.textSecColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${entry.value}',
                    style: AppTypography.bodyS,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.flatId,
    required this.currentFilters,
  });

  final String flatId;
  final AuditLogFilters currentFilters;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _selectedAction;
  String? _selectedEntityType;

  @override
  void initState() {
    super.initState();
    _selectedAction = widget.currentFilters.action;
    _selectedEntityType = widget.currentFilters.entityType;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizing.pagePadding,
        right: AppSizing.pagePadding,
        top: AppSizing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSizing.md),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Filter Audit Logs',
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSizing.md),

          // Action filter
          DropdownButtonFormField<String?>(
            value: _selectedAction,
            decoration: InputDecoration(
              labelText: 'Action',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                borderSide: BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizing.md,
                vertical: AppSizing.sm,
              ),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Actions'),
              ),
              ..._kAllActions.map(
                (a) => DropdownMenuItem<String?>(
                  value: a,
                  child: Text(_actionLabel(a)),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _selectedAction = v),
          ),
          const SizedBox(height: AppSizing.md),

          // Entity type filter
          DropdownButtonFormField<String?>(
            value: _selectedEntityType,
            decoration: InputDecoration(
              labelText: 'Entity Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                borderSide: BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizing.md,
                vertical: AppSizing.sm,
              ),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Types'),
              ),
              ..._kAllEntityTypes.map(
                (t) => DropdownMenuItem<String?>(
                  value: t,
                  child: Text(t),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _selectedEntityType = v),
          ),
          const SizedBox(height: AppSizing.xl),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<AuditLogBloc>().add(
                          AuditLogFilterChanged(
                            flatId: widget.flatId,
                            filters: const AuditLogFilters(),
                          ),
                        );
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSizing.sm + 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    ),
                  ),
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: AppSizing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<AuditLogBloc>().add(
                          AuditLogFilterChanged(
                            flatId: widget.flatId,
                            filters: AuditLogFilters(
                              action: _selectedAction,
                              entityType: _selectedEntityType,
                            ),
                          ),
                        );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSizing.sm + 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
