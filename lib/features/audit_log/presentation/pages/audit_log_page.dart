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
  if (action.startsWith('FLAT_')) return AppColors.primary;
  if (action.startsWith('COMPLAINT_')) return Colors.orange;
  if (action.startsWith('TASK_')) return Colors.blue;
  if (action == 'PAYMENT_VERIFIED' ||
      action == 'EXPENSE_APPROVED' ||
      action == 'FIXED_CONTRIBUTION_AUTO_DEDUCTED' ||
      action == 'MONTH_CLOSED') {
    return AppColors.success;
  }
  if (action.startsWith('MEAL_')) return Colors.amber;
  if (action == 'EXIT_FINALISED' || action == 'MANAGER_TRANSFERRED') {
    return Colors.purple.shade300;
  }
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

// ── Time-ago helper ───────────────────────────────────────────────────────────

String _timeAgo(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal() ?? DateTime.now();
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
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
      builder: (_) => _FilterSheet(
        flatId: widget.args.flatId,
        currentFilters: current,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: Text(
          'Audit Log',
          style: AppTypography.titleLarge.copyWith(color: AppColors.white),
        ),
        actions: [
          BlocBuilder<AuditLogBloc, AuditLogState>(
            builder: (context, state) {
              final filters = state is AuditLogLoaded
                  ? state.filters
                  : const AuditLogFilters();
              return IconButton(
                icon: const Icon(Icons.filter_list, color: AppColors.white),
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
              child: CircularProgressIndicator(color: AppColors.primary),
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
              // Active filter chips
              if (hasActiveFilter)
                Container(
                  width: double.infinity,
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.pagePadding,
                    vertical: AppSizing.xs,
                  ),
                  child: Wrap(
                    spacing: AppSizing.xs,
                    children: [
                      if (filters.action != null)
                        Chip(
                          label: Text(
                            _actionLabel(filters.action!),
                            style: AppTypography.bodySmall,
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            context.read<AuditLogBloc>().add(
                                  AuditLogFilterChanged(
                                    flatId: widget.args.flatId,
                                    filters: filters.copyWith(action: null),
                                  ),
                                );
                          },
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                      if (filters.entityType != null)
                        Chip(
                          label: Text(
                            filters.entityType!,
                            style: AppTypography.bodySmall,
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            context.read<AuditLogBloc>().add(
                                  AuditLogFilterChanged(
                                    flatId: widget.args.flatId,
                                    filters:
                                        filters.copyWith(entityType: null),
                                  ),
                                );
                          },
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),

              // List
              Expanded(
                child: logs.isEmpty
                    ? RefreshIndicator(
                        color: AppColors.primary,
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
                                  MediaQuery.of(context).size.height * 0.3,
                            ),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 64,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No audit logs found',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          context.read<AuditLogBloc>().add(
                                AuditLogLoadRequested(
                                  flatId: widget.args.flatId,
                                  filters: filters,
                                ),
                              );
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: logs.length + (isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == logs.length) {
                              return const Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            return _AuditLogTile(log: logs[index]);
                          },
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

// ── Audit Log Tile ────────────────────────────────────────────────────────────

class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({required this.log});

  final AuditLogEntity log;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(log.action);
    final icon = _categoryIcon(log.action);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizing.pagePadding,
        vertical: AppSizing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSizing.md,
          vertical: AppSizing.xs,
        ),
        childrenPadding: const EdgeInsets.only(
          left: AppSizing.md,
          right: AppSizing.md,
          bottom: AppSizing.md,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          _actionLabel(log.action),
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  log.performedByName ?? 'System',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _timeAgo(log.createdAt),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        children: [
          _ExpandedContent(log: log),
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
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
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
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
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
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
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
        color: AppColors.surfaceVariant,
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
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${entry.value}',
                    style: AppTypography.bodySmall,
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
            style: AppTypography.titleLarge,
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
                    backgroundColor: AppColors.primary,
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
