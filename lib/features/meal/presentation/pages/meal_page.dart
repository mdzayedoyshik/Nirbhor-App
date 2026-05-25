import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/meal_pref_day_entity.dart';
import '../../domain/entities/meal_toggle_entity.dart';
import '../args/meal_page_args.dart';
import '../bloc/meal_bloc.dart';
import '../bloc/meal_pool_bloc.dart';
import '../bloc/meal_prefs_bloc.dart';
import '../widgets/meal_flat_toggle_sheet.dart';
import '../widgets/member_meal_row.dart';
import '../widgets/pool_breakdown_row.dart';

const _shiftColors = {
  'breakfast': Color(0xFFF59E0B),
  'lunch': Color(0xFF10B981),
  'dinner': Color(0xFF6C63FF),
};
const _shiftIcons = {
  'breakfast': Icons.wb_sunny_outlined,
  'lunch': Icons.restaurant_outlined,
  'dinner': Icons.nights_stay_outlined,
};
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _todayIso() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

class MealPage extends StatelessWidget {
  const MealPage({super.key, required this.args});

  final MealPageArgs args;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          title: const Text('Meals'),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: AppColors.white,
            labelColor: AppColors.white,
            unselectedLabelColor: Color(0xCCFFFFFF),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Daily'),
              Tab(text: 'Pool'),
              Tab(text: 'Preferences'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DailyTab(args: args),
            _PoolTab(args: args),
            _PrefsTab(args: args),
          ],
        ),
      ),
    );
  }
}

// ── Daily Tab ─────────────────────────────────────────────────────────────────

class _DailyTab extends StatefulWidget {
  final MealPageArgs args;

  const _DailyTab({required this.args});

  @override
  State<_DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends State<_DailyTab>
    with AutomaticKeepAliveClientMixin {
  late String _selectedDate;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedDate = _todayIso();
    context.read<MealBloc>().add(
          MealDailyLoadRequested(
              flatId: widget.args.flatId, date: _selectedDate),
        );
  }

  void _changeDate(int delta) {
    final current = DateTime.parse(_selectedDate);
    final next = current.add(Duration(days: delta));
    final newDate =
        '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
    setState(() => _selectedDate = newDate);
    context.read<MealBloc>().add(
          MealDailyDateChanged(
              flatId: widget.args.flatId, date: newDate),
        );
  }

  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    return '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocConsumer<MealBloc, MealState>(
      listener: (context, state) {
        if (state is MealActionSuccess) {
          AppSnackbar.success(context, state.message);
        } else if (state is MealActionError) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is MealLoading;
        final isActionLoading = state is MealActionInProgress;

        if (state is MealLoadError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<MealBloc>().add(
                  MealDailyLoadRequested(
                      flatId: widget.args.flatId, date: _selectedDate),
                ),
          );
        }

        final config = switch (state) {
          MealDailyLoaded(config: final c) => c,
          MealActionInProgress(config: final c) => c,
          MealActionSuccess(config: final c) => c,
          MealActionError(config: final c) => c,
          _ => null,
        };
        final logsData = switch (state) {
          MealDailyLoaded(logs: final l) => l,
          MealActionInProgress(logs: final l) => l,
          MealActionSuccess(logs: final l) => l,
          MealActionError(logs: final l) => l,
          _ => null,
        };

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            context.read<MealBloc>().add(MealDailyDateChanged(
                  flatId: widget.args.flatId,
                  date: _selectedDate,
                ));
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            slivers: [
              // Date navigation
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.fromLTRB(
                      AppSizing.pagePadding, 0, AppSizing.pagePadding, AppSizing.md),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left,
                            color: AppColors.white),
                        onPressed: isActionLoading ? null : () => _changeDate(-1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Expanded(
                        child: Text(
                          _formatDate(_selectedDate),
                          style: AppTypography.titleMedium
                              .copyWith(color: AppColors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right,
                            color: AppColors.white),
                        onPressed: isActionLoading ? null : () => _changeDate(1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),

              if (isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (logsData != null && config != null) ...[
                // Shift summary cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizing.pagePadding, AppSizing.md, AppSizing.pagePadding, 0),
                    child: Row(
                      children: ['breakfast', 'lunch', 'dinner'].map((shift) {
                        final count = logsData.shiftTotals.forShift(shift);
                        final enabled = logsData.flatToggle.isEnabled(shift);
                        final color = _shiftColors[shift]!;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: AppSizing.sm),
                            child: _ShiftSummaryCard(
                              icon: _shiftIcons[shift]!,
                              label: shift == 'breakfast'
                                  ? 'Breakfast'
                                  : shift == 'lunch'
                                      ? 'Lunch'
                                      : 'Dinner',
                              membersCount: count.members,
                              guestsCount: count.guests,
                              total: count.totalServings,
                              enabled: enabled,
                              color: color,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Manager: flat toggle row
                if (widget.args.canManage)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizing.pagePadding, AppSizing.md, AppSizing.pagePadding, 0),
                      child: _FlatToggleCard(
                        flatToggle: logsData.flatToggle,
                        onTap: isActionLoading
                            ? null
                            : () => showFlatToggleSheet(
                                  context: context,
                                  flatId: widget.args.flatId,
                                  currentDate: _selectedDate,
                                  flatToggle: logsData.flatToggle,
                                ),
                      ),
                    ),
                  ),

                // Action loading overlay
                if (isActionLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizing.sm),
                      child: LinearProgressIndicator(
                        color: AppColors.primary,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ),

                // Member logs list
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizing.pagePadding, AppSizing.md, AppSizing.pagePadding, AppSizing.xxl),
                  sliver: SliverList.separated(
                    itemCount: logsData.logs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSizing.sm),
                    itemBuilder: (context, i) {
                      final entry = logsData.logs[i];
                      final isOwn =
                          entry.flatMemberId == widget.args.myMemberId;
                      return MemberMealRow(
                        flatId: widget.args.flatId,
                        currentDate: _selectedDate,
                        entry: entry,
                        config: config,
                        flatToggle: logsData.flatToggle,
                        isManager: widget.args.canManage,
                        isOwn: isOwn,
                        isToday: _selectedDate == _todayIso(),
                      );
                    },
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

// ── Pool Tab ──────────────────────────────────────────────────────────────────

class _PoolTab extends StatefulWidget {
  final MealPageArgs args;

  const _PoolTab({required this.args});

  @override
  State<_PoolTab> createState() => _PoolTabState();
}

class _PoolTabState extends State<_PoolTab>
    with AutomaticKeepAliveClientMixin {
  late int _month;
  late int _year;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _load();
  }

  void _load() {
    context.read<MealPoolBloc>().add(MealPoolLoadRequested(
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
    _load();
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<MealPoolBloc, MealPoolState>(
      builder: (context, state) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            _load();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            slivers: [
              // Month navigation
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.fromLTRB(
                      AppSizing.pagePadding, 0, AppSizing.pagePadding, AppSizing.md),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left,
                            color: AppColors.white),
                        onPressed: _prevMonth,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Expanded(
                        child: Text(
                          '${_months[_month - 1]} $_year',
                          style: AppTypography.titleMedium
                              .copyWith(color: AppColors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right,
                            color: AppColors.white),
                        onPressed: _nextMonth,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),

              if (state is MealPoolLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (state is MealPoolError)
                SliverFillRemaining(
                  child: _ErrorView(
                    message: state.message,
                    onRetry: _load,
                  ),
                )
              else if (state is MealPoolLoaded) ...[
                // Summary cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizing.pagePadding),
                    child: Column(
                      children: [
                        // Status badge
                        if (state.pool.isClosed)
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: AppSizing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSizing.radiusMd),
                              border: Border.all(
                                  color: AppColors.success
                                      .withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_rounded,
                                    size: 14, color: AppColors.success),
                                const SizedBox(width: AppSizing.xs),
                                Text(
                                  'Pool Closed — Final',
                                  style: AppTypography.titleMedium.copyWith(
                                      color: AppColors.success),
                                ),
                              ],
                            ),
                          ),
                        if (state.pool.isClosed)
                          const SizedBox(height: AppSizing.md),

                        // 3 stat cards
                        Row(
                          children: [
                            _PoolStatCard(
                              label: 'Total Expense',
                              value:
                                  '৳${state.pool.totalExpense.toStringAsFixed(0)}',
                              icon: Icons.receipt_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSizing.sm),
                            _PoolStatCard(
                              label: 'Total Points',
                              value: state.pool.totalPoints.toStringAsFixed(1),
                              icon: Icons.star_outline_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: AppSizing.sm),
                            _PoolStatCard(
                              label: 'Per Point',
                              value:
                                  '৳${state.pool.perPointCost.toStringAsFixed(2)}',
                              icon: Icons.calculate_outlined,
                              color: AppColors.success,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Breakdown header
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizing.pagePadding, 0, AppSizing.pagePadding, AppSizing.sm),
                  sliver: SliverToBoxAdapter(
                    child: Text('Member Breakdown',
                        style: AppTypography.headlineSmall),
                  ),
                ),

                // Breakdown list
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizing.pagePadding, 0, AppSizing.pagePadding, AppSizing.xxl),
                  sliver: SliverList.separated(
                    itemCount: state.pool.memberBreakdown.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSizing.sm),
                    itemBuilder: (context, i) {
                      final member = state.pool.memberBreakdown[i];
                      final isMe =
                          member.flatMemberId == widget.args.myMemberId;
                      return PoolBreakdownRow(member: member, isMe: isMe);
                    },
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

// ── Preferences Tab ───────────────────────────────────────────────────────────

class _PrefsTab extends StatefulWidget {
  final MealPageArgs args;

  const _PrefsTab({required this.args});

  @override
  State<_PrefsTab> createState() => _PrefsTabState();
}

class _PrefsTabState extends State<_PrefsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<MealPrefsBloc>().add(MealPrefsLoadRequested(
          flatId: widget.args.flatId,
          memberId: widget.args.myMemberId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocConsumer<MealPrefsBloc, MealPrefsState>(
      listener: (context, state) {
        if (state is MealPrefsSaveSuccess) {
          AppSnackbar.success(context, 'Preferences saved.');
        } else if (state is MealPrefsError) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is MealPrefsLoading || state is MealPrefsInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is MealPrefsError && state.prefs == null) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<MealPrefsBloc>().add(
                  MealPrefsLoadRequested(
                    flatId: widget.args.flatId,
                    memberId: widget.args.myMemberId,
                  ),
                ),
          );
        }

        List<MealPrefDayEntity>? prefs;
        if (state is MealPrefsLoaded) prefs = state.prefs;
        if (state is MealPrefsSaving) prefs = state.prefs;
        if (state is MealPrefsSaveSuccess) prefs = state.prefs;
        if (state is MealPrefsError && state.prefs != null) prefs = state.prefs;

        final isDirty = state is MealPrefsLoaded && state.isDirty;
        final isSaving = state is MealPrefsSaving;

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSizing.pagePadding, AppSizing.md, AppSizing.pagePadding, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Meal Preferences',
                    style: AppTypography.headlineSmall,
                  ),
                  const SizedBox(height: AppSizing.xs),
                  Text(
                    'Set your default meals for each day. These are used when you haven\'t toggled a specific day.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSizing.lg),

                  // Grid header row
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizing.sm),
                    child: Row(
                      children: [
                        const SizedBox(width: 48),
                        ...['breakfast', 'lunch', 'dinner'].map((shift) {
                          final color = _shiftColors[shift]!;
                          return Expanded(
                            child: Column(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppSizing.radiusMd),
                                  ),
                                  child: Icon(
                                    _shiftIcons[shift],
                                    size: 16,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  shift == 'breakfast'
                                      ? 'B'
                                      : shift == 'lunch'
                                          ? 'L'
                                          : 'D',
                                  style: AppTypography.labelSmall
                                      .copyWith(color: color),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Day rows
                  if (prefs != null)
                    ...List.generate(prefs.length, (i) {
                      final pref = prefs![i];
                      final shortDay = pref.dayName.length >= 3
                          ? pref.dayName.substring(0, 3)
                          : pref.dayName;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSizing.sm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizing.sm,
                              vertical: AppSizing.sm + 2),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppSizing.radiusMd),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 48,
                                child: Text(shortDay,
                                    style: AppTypography.titleMedium),
                              ),
                              ...[
                                ('breakfast', pref.breakfast),
                                ('lunch', pref.lunch),
                                ('dinner', pref.dinner),
                              ].map(((String, bool) entry) {
                                final shift = entry.$1;
                                final value = entry.$2;
                                final color = _shiftColors[shift]!;
                                return Expanded(
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: isSaving
                                          ? null
                                          : () => context
                                              .read<MealPrefsBloc>()
                                              .add(MealPrefsDayToggled(
                                                dayOfWeek: pref.dayOfWeek,
                                                shift: shift,
                                              )),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: value
                                              ? color.withValues(alpha: 0.15)
                                              : AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(
                                              AppSizing.radiusMd),
                                          border: Border.all(
                                            color: value
                                                ? color.withValues(alpha: 0.4)
                                                : AppColors.border,
                                          ),
                                        ),
                                        child: Icon(
                                          value
                                              ? Icons.check_rounded
                                              : Icons.close_rounded,
                                          size: 16,
                                          color: value
                                              ? color
                                              : AppColors.textHint,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),

            // Sticky save button
            if (isDirty || isSaving)
              Positioned(
                left: AppSizing.pagePadding,
                right: AppSizing.pagePadding,
                bottom: AppSizing.lg,
                child: FilledButton(
                  onPressed: isSaving
                      ? null
                      : () => context.read<MealPrefsBloc>().add(
                            MealPrefsSaveRequested(
                              flatId: widget.args.flatId,
                              memberId: widget.args.myMemberId,
                            ),
                          ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.6),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSizing.sm + 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white),
                        )
                      : const Text('Save Preferences'),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Shift summary card ────────────────────────────────────────────────────────

class _ShiftSummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int membersCount;
  final int guestsCount;
  final int total;
  final bool enabled;
  final Color color;

  const _ShiftSummaryCard({
    required this.icon,
    required this.label,
    required this.membersCount,
    required this.guestsCount,
    required this.total,
    required this.enabled,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.sm),
      decoration: BoxDecoration(
        color: enabled
            ? color.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(
          color: enabled ? color.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 14,
                  color: enabled ? color : AppColors.textHint),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: enabled ? color : AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            enabled ? '$total' : '—',
            style: AppTypography.headlineMedium.copyWith(
              color: enabled ? color : AppColors.textHint,
              fontSize: 20,
            ),
          ),
          if (enabled && guestsCount > 0)
            Text(
              '+$guestsCount guests',
              style: AppTypography.labelSmall
                  .copyWith(color: color.withValues(alpha: 0.7), fontSize: 10),
            ),
          if (!enabled)
            Text(
              'off',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textHint, fontSize: 10),
            ),
        ],
      ),
    );
  }
}

// ── Flat toggle card ──────────────────────────────────────────────────────────

class _FlatToggleCard extends StatelessWidget {
  final MealToggleEntity flatToggle;
  final VoidCallback? onTap;

  const _FlatToggleCard({required this.flatToggle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.md, vertical: AppSizing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.toggle_on_outlined,
                size: 18, color: AppColors.primary),
            const SizedBox(width: AppSizing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flat Shifts', style: AppTypography.titleMedium),
                  Text(
                    'Manage which shifts are active today',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Row(
              children: ['breakfast', 'lunch', 'dinner'].map((shift) {
                final active = flatToggle.isEnabled(shift);
                final color = _shiftColors[shift]!;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? color : AppColors.textHint,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: AppSizing.sm),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ── Pool stat card ────────────────────────────────────────────────────────────

class _PoolStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PoolStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizing.sm + 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: AppSizing.xs),
            Text(
              value,
              style: AppTypography.titleLarge
                  .copyWith(color: color, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSizing.md),
            Text(message,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSizing.md),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
