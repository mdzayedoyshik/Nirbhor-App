import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/close_preview_entity.dart';
import '../../domain/entities/closed_month_entity.dart';
import '../../domain/entities/month_summary_entity.dart';
import '../../domain/entities/month_summary_member_entity.dart';
import '../args/summary_page_args.dart';
import '../bloc/summary_bloc.dart';
import '../bloc/summary_event.dart';
import '../bloc/summary_state.dart';

const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _monthLabel(int month, int year) => '${_monthNames[month - 1]} $year';

String _shortMonth(int month) => _monthNames[month - 1].substring(0, 3);

String _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final dt = DateTime.parse(iso).toLocal();
    return '${_shortMonth(dt.month)} ${dt.day}, ${dt.year}';
  } catch (_) {
    return '';
  }
}

String _taka(double amount) {
  final abs = amount.abs();
  final str = abs >= 1000
      ? '${(abs / 1000).toStringAsFixed(1)}k'
      : abs.toStringAsFixed(abs == abs.truncate() ? 0 : 2);
  return amount < 0 ? '-৳$str' : '৳$str';
}

// Returns a stable color for each member based on name
Color _memberColor(String name) {
  const palette = [
    Color(0xFF6C63FF),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
  ];
  if (name.isEmpty) return palette[0];
  return palette[name.codeUnitAt(0) % palette.length];
}

// ─────────────────────────────────────────────────────────────────────────────

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key, required this.args});

  final SummaryPageArgs args;

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage>
    with SingleTickerProviderStateMixin {
  late int _month;
  late int _year;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _load() {
    context.read<SummaryBloc>().add(SummaryLoadRequested(
          flatId: widget.args.flatId,
          month: _month,
          year: _year,
        ));
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
    context.read<SummaryBloc>().add(SummaryLoadRequested(
          flatId: widget.args.flatId,
          month: _month,
          year: _year,
        ));
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_year > now.year || (_year == now.year && _month >= now.month)) return;
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
    context.read<SummaryBloc>().add(SummaryLoadRequested(
          flatId: widget.args.flatId,
          month: _month,
          year: _year,
        ));
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month == now.month && _year == now.year;
  }

  void _showCloseSheet(SummaryLoaded state) async {
    context
        .read<SummaryBloc>()
        .add(SummaryPreviewRequested(widget.args.flatId));

    final bloc = context.read<SummaryBloc>();
    await AppBottomSheet.show(
      context: context,
      isScrollControlled: true,
      child: BlocProvider.value(
        value: bloc,
        child: _CloseMonthSheet(
          args: widget.args,
          month: _month,
          year: _year,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SummaryBloc, SummaryState>(
      listener: (context, state) {
        if (state is SummaryCloseSuccess) {
          AppSnackbar.success(
            context,
            '${_monthLabel(state.month, state.year)} closed successfully.',
          );
          setState(() {
            _month = state.month;
            _year = state.year;
          });
          context.read<SummaryBloc>().add(SummaryLoadRequested(
                flatId: widget.args.flatId,
                month: state.month,
                year: state.year,
              ));
          context.read<SummaryBloc>().add(
                SummaryClosedMonthsLoadRequested(widget.args.flatId),
              );
        } else if (state is SummaryCloseError) {
          AppSnackbar.error(context, state.message);
          // Restore loaded state so page remains usable
          context.read<SummaryBloc>().add(SummaryLoadRequested(
                flatId: widget.args.flatId,
                month: _month,
                year: _year,
              ));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            title: Text(
              'Monthly Summary',
              style: AppTypography.headlineSmall
                  .copyWith(color: AppColors.white),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.white,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
              labelStyle: AppTypography.titleMedium,
              unselectedLabelStyle: AppTypography.bodyMedium,
              tabs: const [
                Tab(text: 'Summary'),
                Tab(text: 'History'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _SummaryTab(
                state: state,
                month: _month,
                year: _year,
                isCurrentMonth: _isCurrentMonth,
                args: widget.args,
                onPrev: _prevMonth,
                onNext: _nextMonth,
                onClose: () {
                  if (state is SummaryLoaded) _showCloseSheet(state);
                },
                onRefresh: _load,
              ),
              _HistoryTab(
                state: state,
                onMonthTap: (m, y) {
                  setState(() {
                    _month = m;
                    _year = y;
                  });
                  context.read<SummaryBloc>().add(SummaryLoadRequested(
                        flatId: widget.args.flatId,
                        month: m,
                        year: y,
                      ));
                  _tabController.animateTo(0);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Summary Tab ──────────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.state,
    required this.month,
    required this.year,
    required this.isCurrentMonth,
    required this.args,
    required this.onPrev,
    required this.onNext,
    required this.onClose,
    required this.onRefresh,
  });

  final SummaryState state;
  final int month;
  final int year;
  final bool isCurrentMonth;
  final SummaryPageArgs args;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        onRefresh();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: AppSizing.md),
                _MonthNavigator(
                  month: month,
                  year: year,
                  isCurrentMonth: isCurrentMonth,
                  onPrev: onPrev,
                  onNext: onNext,
                ),
                const SizedBox(height: AppSizing.md),
                if (state is SummaryLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (state is SummaryError)
                  Padding(
                    padding: const EdgeInsets.all(AppSizing.pagePadding),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: AppSizing.sm),
                        Text(
                          (state as SummaryError).message,
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizing.lg),
                        AppButton(
                          label: 'Retry',
                          variant: AppButtonVariant.outlined,
                          fullWidth: false,
                          onPressed: onRefresh,
                        ),
                      ],
                    ),
                  )
                else if (state is SummaryLoaded) ...[
                  _SummaryContent(
                    summary: (state as SummaryLoaded).summary,
                    myMemberId: args.myMemberId,
                    isManager: args.isManager,
                    isCurrentMonth: isCurrentMonth,
                    onClose: onClose,
                  ),
                ] else if (state is SummaryCloseSuccess) ...[
                  _SummaryContent(
                    summary: (state as SummaryCloseSuccess).summary,
                    myMemberId: args.myMemberId,
                    isManager: args.isManager,
                    isCurrentMonth: isCurrentMonth,
                    onClose: onClose,
                  ),
                ] else if (state is SummaryCloseError) ...[
                  _SummaryContent(
                    summary: (state as SummaryCloseError).summary,
                    myMemberId: args.myMemberId,
                    isManager: args.isManager,
                    isCurrentMonth: isCurrentMonth,
                    onClose: onClose,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.year,
    required this.isCurrentMonth,
    required this.onPrev,
    required this.onNext,
  });

  final int month;
  final int year;
  final bool isCurrentMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: AppColors.textPrimary,
            onPressed: onPrev,
          ),
          Column(
            children: [
              Text(
                _monthLabel(month, year),
                style: AppTypography.headlineSmall,
              ),
              const SizedBox(height: 2),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              size: 28,
              color: isCurrentMonth
                  ? AppColors.textHint
                  : AppColors.textPrimary,
            ),
            onPressed: isCurrentMonth ? null : onNext,
          ),
        ],
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({
    required this.summary,
    required this.myMemberId,
    required this.isManager,
    required this.isCurrentMonth,
    required this.onClose,
  });

  final MonthSummaryEntity summary;
  final String myMemberId;
  final bool isManager;
  final bool isCurrentMonth;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
          child: _StatusBadge(isClosed: summary.isClosed, closedAt: summary.closedAt),
        ),
        const SizedBox(height: AppSizing.md),

        // Pool stats card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
          child: _PoolCard(summary: summary),
        ),
        const SizedBox(height: AppSizing.lg),

        // Members heading
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
          child: Row(
            children: [
              Text('Members', style: AppTypography.headlineSmall),
              const SizedBox(width: AppSizing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                ),
                child: Text(
                  '${summary.members.length}',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizing.sm),

        // Member cards
        if (summary.members.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSizing.pagePadding),
            child: Center(
              child: Text(
                'No members found for this month.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...summary.members.map(
            (m) => Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizing.pagePadding, 0, AppSizing.pagePadding, AppSizing.sm),
              child: _MemberCard(
                member: m,
                isMe: m.flatMemberId == myMemberId,
              ),
            ),
          ),

        // Close month button (manager + open + current month)
        if (isManager && !summary.isClosed && isCurrentMonth) ...[
          const SizedBox(height: AppSizing.md),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizing.pagePadding),
            child: AppButton(
              label: 'Close This Month',
              icon: const Icon(Icons.lock_outline, color: AppColors.white, size: 18),
              onPressed: onClose,
            ),
          ),
        ],
        const SizedBox(height: AppSizing.xl),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isClosed, this.closedAt});

  final bool isClosed;
  final String? closedAt;

  @override
  Widget build(BuildContext context) {
    if (isClosed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Closed',
                  style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success, fontWeight: FontWeight.w600),
                ),
                if (closedAt != null && closedAt!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    '· ${_formatDate(closedAt)}',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Live Preview',
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PoolCard extends StatelessWidget {
  const _PoolCard({required this.summary});

  final MonthSummaryEntity summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal Pool',
            style: AppTypography.titleMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizing.md),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Total',
                  value: _taka(summary.totalExpense),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizing.sm),
              Expanded(
                child: _StatChip(
                  label: 'Points',
                  value: summary.totalPoints.toStringAsFixed(0),
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSizing.sm),
              Expanded(
                child: _StatChip(
                  label: 'Per Pt.',
                  value: summary.totalPoints > 0
                      ? '৳${summary.perPointCost.toStringAsFixed(2)}'
                      : '—',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSizing.sm, horizontal: AppSizing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.isMe});

  final MonthSummaryMemberEntity member;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final color = _memberColor(member.memberName);
    final isBalance = member.isBalance;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(
          color: isMe ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Colored side bar
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: isBalance ? AppColors.success : AppColors.error,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizing.radiusLg),
                bottomLeft: Radius.circular(AppSizing.radiusLg),
              ),
            ),
          ),
          const SizedBox(width: AppSizing.sm),

          // Avatar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizing.sm),
            child: AppAvatar(
              name: member.memberName,
              radius: 20,
              backgroundColor: color,
            ),
          ),
          const SizedBox(width: AppSizing.sm),

          // Member info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.memberName,
                          style: AppTypography.titleMedium
                              .copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: AppSizing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizing.radiusFull),
                          ),
                          child: Text(
                            'You',
                            style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${member.mealPoints.toStringAsFixed(0)} pts · '
                    'Meal ${_taka(member.mealCost)} · '
                    'Fixed ${_taka(member.fixedContribution)}',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Balance
          Padding(
            padding: const EdgeInsets.only(right: AppSizing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _taka(member.balance),
                  style: AppTypography.titleMedium.copyWith(
                    color: isBalance ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isBalance ? 'Balance' : 'Due',
                  style: AppTypography.labelSmall.copyWith(
                    color: isBalance ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History Tab ──────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.state, required this.onMonthTap});

  final SummaryState state;
  final void Function(int month, int year) onMonthTap;

  @override
  Widget build(BuildContext context) {
    if (state is SummaryLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    List<ClosedMonthEntity> months = [];
    bool isLoading = false;

    if (state is SummaryLoaded) {
      months = (state as SummaryLoaded).closedMonths;
      isLoading = (state as SummaryLoaded).isClosedMonthsLoading;
    } else if (state is SummaryCloseSuccess) {
      months = (state as SummaryCloseSuccess).closedMonths;
    } else if (state is SummaryCloseError) {
      months = (state as SummaryCloseError).closedMonths;
    }

    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (months.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_rounded, size: 56, color: AppColors.textHint),
            const SizedBox(height: AppSizing.md),
            Text(
              'No closed months yet',
              style: AppTypography.headlineSmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizing.xs),
            Text(
              'Closed months will appear here.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizing.pagePadding),
      itemCount: months.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSizing.sm),
      itemBuilder: (context, index) {
        final m = months[index];
        return _ClosedMonthTile(
          month: m,
          onTap: () => onMonthTap(m.month, m.year),
        );
      },
    );
  }
}

class _ClosedMonthTile extends StatelessWidget {
  const _ClosedMonthTile({required this.month, required this.onTap});

  final ClosedMonthEntity month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSizing.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSizing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _monthLabel(month.month, month.year),
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${month.totalMembers} members · Closed ${_formatDate(month.closedAt)}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _taka(month.totalMealExpense),
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Meal exp.',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(width: AppSizing.xs),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Close Month Bottom Sheet ─────────────────────────────────────────────────

class _CloseMonthSheet extends StatefulWidget {
  const _CloseMonthSheet({
    required this.args,
    required this.month,
    required this.year,
  });

  final SummaryPageArgs args;
  final int month;
  final int year;

  @override
  State<_CloseMonthSheet> createState() => _CloseMonthSheetState();
}

class _CloseMonthSheetState extends State<_CloseMonthSheet> {
  bool _forceClose = false;

  void _close(BuildContext context) {
    context.read<SummaryBloc>().add(SummaryCloseMonthRequested(
          flatId: widget.args.flatId,
          month: widget.month,
          year: widget.year,
          force: _forceClose,
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SummaryBloc, SummaryState>(
      builder: (context, state) {
        final loadedState = state is SummaryLoaded ? state : null;
        final preview = loadedState?.preview;
        final isPreviewLoading = loadedState?.isPreviewLoading ?? true;
        final isClosing = loadedState?.isClosing ?? false;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizing.pagePadding, AppSizing.md,
                    AppSizing.pagePadding, 0),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: AppSizing.sm),
                    Text(
                      'Close ${_monthLabel(widget.month, widget.year)}',
                      style: AppTypography.headlineSmall,
                    ),
                  ],
                ),
              ),

              if (isPreviewLoading) ...[
                const Padding(
                  padding: EdgeInsets.all(AppSizing.xl),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ] else if (preview != null) ...[
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizing.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pool summary row
                        _PreviewPoolRow(preview: preview),
                        const SizedBox(height: AppSizing.md),

                        // Warnings
                        if (preview.hasWarnings) ...[
                          _WarningBox(
                            warnings: preview.warnings,
                            forceClose: _forceClose,
                            onForceToggled: (v) =>
                                setState(() => _forceClose = v),
                          ),
                          const SizedBox(height: AppSizing.md),
                        ],

                        // Member impacts
                        Text(
                          'Member Impact',
                          style: AppTypography.titleMedium
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSizing.sm),
                        ...preview.memberPreviews.map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSizing.sm),
                            child: _PreviewMemberRow(member: m),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizing.pagePadding,
                      0, AppSizing.pagePadding, AppSizing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Cancel',
                          variant: AppButtonVariant.outlined,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSizing.md),
                      Expanded(
                        child: AppButton(
                          label: 'Close Month',
                          loading: isClosing,
                          onPressed: (preview.hasWarnings && !_forceClose)
                              ? null
                              : () => _close(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.all(AppSizing.pagePadding),
                  child: Text(
                    'Unable to load preview. Please try again.',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PreviewPoolRow extends StatelessWidget {
  const _PreviewPoolRow({required this.preview});

  final ClosePreviewEntity preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat(
              label: 'Total',
              value: _taka(preview.totalExpense),
              color: AppColors.primary),
          _MiniStat(
              label: 'Points',
              value: preview.totalPoints.toStringAsFixed(0),
              color: AppColors.warning),
          _MiniStat(
              label: 'Per pt.',
              value: preview.totalPoints > 0
                  ? '৳${preview.perPointCost.toStringAsFixed(2)}'
                  : '—',
              color: AppColors.success),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleMedium
              .copyWith(color: color, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style:
              AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox({
    required this.warnings,
    required this.forceClose,
    required this.onForceToggled,
  });

  final List<String> warnings;
  final bool forceClose;
  final ValueChanged<bool> onForceToggled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 18),
              const SizedBox(width: AppSizing.xs),
              Text(
                'Warnings',
                style: AppTypography.titleMedium
                    .copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSizing.xs),
          ...warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• $w',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: AppSizing.sm),
          Row(
            children: [
              Switch(
                value: forceClose,
                onChanged: onForceToggled,
                activeThumbColor: AppColors.warning,
                activeTrackColor: AppColors.warning.withValues(alpha: 0.35),
              ),
              const SizedBox(width: AppSizing.xs),
              Expanded(
                child: Text(
                  'Force close anyway',
                  style: AppTypography.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewMemberRow extends StatelessWidget {
  const _PreviewMemberRow({required this.member});

  final ClosePreviewMemberEntity member;

  @override
  Widget build(BuildContext context) {
    final color = _memberColor(member.memberName);
    final isBalance = member.isProjectedBalance;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.sm, vertical: AppSizing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          AppAvatar(name: member.memberName, radius: 18, backgroundColor: color),
          const SizedBox(width: AppSizing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.memberName,
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Meal deduction: -${_taka(member.mealCost)}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _taka(member.projectedWalletBalance),
                style: AppTypography.titleMedium.copyWith(
                  color: isBalance ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                isBalance ? 'After close' : 'Will owe',
                style: AppTypography.labelSmall.copyWith(
                  color: isBalance ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
