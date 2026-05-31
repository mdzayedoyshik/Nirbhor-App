import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../flat/domain/entities/flat_member_entity.dart';
import '../../data/datasources/meal_remote_datasource.dart';
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

// ── Tab index constants ────────────────────────────────────────────────────────

const _kTabMeals = 0;

// ── Page root ─────────────────────────────────────────────────────────────────

class MealPage extends StatefulWidget {
  const MealPage({super.key, required this.args});

  final MealPageArgs args;

  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  int _selectedTab = _kTabMeals;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meals', style: AppTypography.headlineMedium),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizing.pagePadding, 0, AppSizing.pagePadding, AppSizing.md),
            child: _PillTabBar(
              selectedIndex: _selectedTab,
              onChanged: (index) => setState(() => _selectedTab = index),
              labels: const ['Meals', 'Pool', 'History', 'Prefs'],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _DailyTab(args: widget.args),
          _PoolTab(args: widget.args),
          _HistoryTab(args: widget.args),
          _PrefsTab(args: widget.args),
        ],
      ),
    );
  }
}

// ── Pill tab bar ──────────────────────────────────────────────────────────────

class _PillTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  const _PillTabBar({
    required this.selectedIndex,
    required this.onChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.rFull),
        border: Border.all(color: context.borderColor),
        boxShadow: AppColors.shadowSm,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.brandGradient : null,
                  color: selected ? null : AppColors.transparent,
                  borderRadius: BorderRadius.circular(AppSizing.rFull),
                  boxShadow: selected ? AppColors.shadowSm : null,
                ),
                alignment: Alignment.center,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTypography.labelM.copyWith(
                    color: selected
                        ? AppColors.white
                        : context.textSecColor,
                  ),
                  child: Text(labels[i]),
                ),
              ),
            ),
          );
        }),
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

  Future<void> _pickDate(BuildContext context) async {
    final current = DateTime.parse(_selectedDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    final newDate =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    if (newDate == _selectedDate) return;
    setState(() => _selectedDate = newDate);
    // ignore: use_build_context_synchronously
    context.read<MealBloc>().add(
          MealDailyDateChanged(flatId: widget.args.flatId, date: newDate),
        );
  }

  void _goToToday() {
    final today = _todayIso();
    if (today == _selectedDate) return;
    setState(() => _selectedDate = today);
    context.read<MealBloc>().add(
          MealDailyDateChanged(flatId: widget.args.flatId, date: today),
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
          // No success snackbar — the toggle visual is sufficient feedback.
          // Refresh the pool breakdown so counts stay in sync.
          context.read<MealPoolBloc>().add(MealPoolLoadRequested(
                flatId: widget.args.flatId,
                month: DateTime.now().month,
                year: DateTime.now().year,
              ));
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
          color: AppColors.brand,
          onRefresh: () async {
            context.read<MealBloc>().add(MealDailyDateChanged(
                  flatId: widget.args.flatId,
                  date: _selectedDate,
                ));
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            slivers: [
              // Date navigation strip
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizing.pagePadding, AppSizing.md, AppSizing.pagePadding, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.sm, vertical: AppSizing.xs),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                      border: Border.all(color: context.borderColor),
                      boxShadow: AppColors.shadowSm,
                    ),
                    child: Row(
                      children: [
                        _NavIconButton(
                          icon: Icons.chevron_left_rounded,
                          onPressed: isActionLoading ? null : () => _changeDate(-1),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: isActionLoading ? null : () => _pickDate(context),
                            child: Text(
                              _formatDate(_selectedDate),
                              style: AppTypography.labelL.copyWith(
                                color: context.textPrimColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        _NavIconButton(
                          icon: Icons.chevron_right_rounded,
                          onPressed: isActionLoading
                              ? null
                              : _selectedDate == _todayIso()
                                  ? null
                                  : () => _changeDate(1),
                        ),
                        if (_selectedDate != _todayIso())
                          _NavIconButton(
                            icon: Icons.today_rounded,
                            onPressed: isActionLoading ? null : _goToToday,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              if (isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.brand),
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
                                  canManage: widget.args.canManage,
                                ),
                      ),
                    ),
                  ),

                // Action loading bar
                if (isActionLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizing.pagePadding, AppSizing.sm, AppSizing.pagePadding, 0),
                      child: LinearProgressIndicator(
                        color: AppColors.brand,
                        backgroundColor:
                            AppColors.brand.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizing.rFull),
                      ),
                    ),
                  ),

                // Section label
                if (logsData.logs.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizing.pagePadding, AppSizing.md, AppSizing.pagePadding, AppSizing.xs),
                      child: Text(
                        'Member Logs',
                        style: AppTypography.labelL.copyWith(
                          color: context.textSecColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                // Member logs list
                if (logsData.logs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyMealState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizing.pagePadding, 0, AppSizing.pagePadding, AppSizing.xxl),
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
          color: AppColors.brand,
          onRefresh: () async {
            _load();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            slivers: [
              // Month navigation strip
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizing.pagePadding, AppSizing.md, AppSizing.pagePadding, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.sm, vertical: AppSizing.xs),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                      border: Border.all(color: context.borderColor),
                      boxShadow: AppColors.shadowSm,
                    ),
                    child: Row(
                      children: [
                        _NavIconButton(
                          icon: Icons.chevron_left_rounded,
                          onPressed: _prevMonth,
                        ),
                        Expanded(
                          child: Text(
                            '${_months[_month - 1]} $_year',
                            style: AppTypography.labelL.copyWith(
                              color: context.textPrimColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _NavIconButton(
                          icon: Icons.chevron_right_rounded,
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (state is MealPoolLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.brand),
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
                // Status badge
                if (state.pool.isClosed)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizing.pagePadding, AppSizing.md, AppSizing.pagePadding, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizing.md, vertical: AppSizing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                          border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_rounded,
                                size: 14, color: AppColors.success),
                            const SizedBox(width: AppSizing.xs),
                            Text(
                              'Pool Closed — Final',
                              style: AppTypography.labelM
                                  .copyWith(color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 3 stat cards in a grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizing.pagePadding, AppSizing.md, AppSizing.pagePadding, 0),
                    child: Row(
                      children: [
                        _PoolStatCard(
                          label: 'Total Expense',
                          value: '৳${state.pool.totalExpense.toStringAsFixed(0)}',
                          icon: Icons.receipt_long_rounded,
                          gradient: AppColors.brandGradient,
                        ),
                        const SizedBox(width: AppSizing.sm),
                        _PoolStatCard(
                          label: 'Total Points',
                          value: state.pool.totalPoints.toStringAsFixed(1),
                          icon: Icons.stars_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        const SizedBox(width: AppSizing.sm),
                        _PoolStatCard(
                          label: 'Per Point',
                          value: '৳${state.pool.perPointCost.toStringAsFixed(2)}',
                          icon: Icons.calculate_rounded,
                          gradient: AppColors.successGradient,
                        ),
                      ],
                    ),
                  ),
                ),

                // Breakdown header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizing.pagePadding, AppSizing.lg, AppSizing.pagePadding, AppSizing.xs),
                    child: Text(
                      'Member Breakdown',
                      style: AppTypography.labelL.copyWith(
                        color: context.textSecColor,
                        letterSpacing: 0.3,
                      ),
                    ),
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
              child: CircularProgressIndicator(color: AppColors.brand));
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
                  // Section title + description
                  Text(
                    'Weekly Meal Preferences',
                    style: AppTypography.h3.copyWith(
                      color: context.textPrimColor,
                    ),
                  ),
                  const SizedBox(height: AppSizing.xs),
                  Text(
                    'Set your default meals for each day. Used when you haven\'t toggled a specific day.',
                    style: AppTypography.bodyS
                        .copyWith(color: context.textSecColor),
                  ),
                  const SizedBox(height: AppSizing.lg),

                  // Grid header row with colored shift icons
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizing.sm),
                    child: Row(
                      children: [
                        const SizedBox(width: 52),
                        ...['breakfast', 'lunch', 'dinner'].map((shift) {
                          final color = _shiftColors[shift]!;
                          return Expanded(
                            child: Column(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        color,
                                        color.withValues(alpha: 0.7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        AppSizing.r12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _shiftIcons[shift],
                                    size: 16,
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(height: AppSizing.xs),
                                Text(
                                  shift == 'breakfast'
                                      ? 'B'
                                      : shift == 'lunch'
                                          ? 'L'
                                          : 'D',
                                  style: AppTypography.labelS
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
                            color: context.cardColor,
                            borderRadius:
                                BorderRadius.circular(AppSizing.radiusMd),
                            border: Border.all(color: context.borderColor),
                            boxShadow: AppColors.shadowSm,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 52,
                                child: Text(
                                  shortDay,
                                  style: AppTypography.labelL.copyWith(
                                    color: context.textPrimColor,
                                  ),
                                ),
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
                                            const Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: value
                                              ? color
                                              : context.surfaceColor,
                                          shape: BoxShape.circle,
                                          boxShadow: value
                                              ? [
                                                  BoxShadow(
                                                    color: color.withValues(
                                                        alpha: 0.35),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Icon(
                                          value
                                              ? Icons.check_rounded
                                              : Icons.remove_rounded,
                                          size: 16,
                                          color: value
                                              ? AppColors.white
                                              : AppColors.textDisabled,
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
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    gradient: isSaving
                        ? null
                        : AppColors.brandGradient,
                    color: isSaving
                        ? AppColors.brand.withValues(alpha: 0.6)
                        : null,
                    boxShadow: isSaving ? null : AppColors.shadowBrand,
                  ),
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
                      backgroundColor: AppColors.transparent,
                      disabledBackgroundColor: AppColors.transparent,
                      minimumSize: const Size(double.infinity, 52),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSizing.sm + 4),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizing.radiusMd),
                      ),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white),
                          )
                        : Text(
                            'Save Preferences',
                            style: AppTypography.labelL
                                .copyWith(color: AppColors.white),
                          ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Shift summary card ────────────────────────────────────────────────────────

class _ShiftSummaryCard extends StatefulWidget {
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
  State<_ShiftSummaryCard> createState() => _ShiftSummaryCardState();
}

class _ShiftSummaryCardState extends State<_ShiftSummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.all(AppSizing.sm + 2),
          decoration: BoxDecoration(
            color: widget.enabled
                ? widget.color.withValues(alpha: 0.08)
                : context.surfaceColor,
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            border: Border.all(
              color: widget.enabled
                  ? widget.color.withValues(alpha: 0.3)
                  : context.borderColor,
            ),
            boxShadow: widget.enabled ? AppColors.shadowSm : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? widget.color.withValues(alpha: 0.15)
                      : AppColors.surface200,
                  borderRadius: BorderRadius.circular(AppSizing.r8),
                ),
                child: Icon(
                  widget.enabled ? widget.icon : widget.icon,
                  size: 16,
                  color: widget.enabled ? widget.color : AppColors.textDisabled,
                ),
              ),
              const SizedBox(height: AppSizing.xs),
              Flexible(
                child: Text(
                  widget.label,
                  style: AppTypography.labelS.copyWith(
                    color: widget.enabled
                        ? widget.color
                        : AppColors.textDisabled,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.enabled ? '${widget.total}' : '—',
                style: AppTypography.h2.copyWith(
                  color: widget.enabled ? widget.color : AppColors.textDisabled,
                  height: 1.1,
                ),
              ),
              if (widget.enabled && widget.guestsCount > 0)
                Text(
                  '+${widget.guestsCount}g',
                  style: AppTypography.labelS.copyWith(
                    color: widget.color.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                )
              else if (!widget.enabled)
                Text(
                  'off',
                  style: AppTypography.labelS.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
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
            horizontal: AppSizing.md, vertical: AppSizing.sm + 2),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: context.borderColor),
          boxShadow: AppColors.shadowSm,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizing.r8),
              ),
              child: const Icon(Icons.tune_rounded,
                  size: 18, color: AppColors.brand),
            ),
            const SizedBox(width: AppSizing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flat Shifts',
                    style: AppTypography.labelL.copyWith(
                      color: context.textPrimColor,
                    ),
                  ),
                  Text(
                    'Manage which shifts are active today',
                    style: AppTypography.labelS
                        .copyWith(color: context.textSecColor),
                  ),
                ],
              ),
            ),
            Row(
              children: ['breakfast', 'lunch', 'dinner'].map((shift) {
                final active = flatToggle.isEnabled(shift);
                final color = _shiftColors[shift]!;
                return Padding(
                  padding: const EdgeInsets.only(left: AppSizing.xs),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: active ? color : context.borderColor,
                      shape: BoxShape.circle,
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 4,
                              )
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: AppSizing.sm),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textDisabled),
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
  final LinearGradient gradient;

  const _PoolStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizing.sm + 2),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: context.borderColor),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient icon container
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppSizing.r8),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 16, color: AppColors.white),
            ),
            const SizedBox(height: AppSizing.xs),
            Text(
              value,
              style: AppTypography.h4.copyWith(
                color: context.textPrimColor,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: AppTypography.labelS
                  .copyWith(color: context.textSecColor, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty meal state ──────────────────────────────────────────────────────────

class _EmptyMealState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '\u{1F37D}',
              style: TextStyle(fontSize: 56),
            ),
            const SizedBox(height: AppSizing.md),
            Text(
              'No meal logs yet',
              style: AppTypography.h3.copyWith(
                color: context.textPrimColor,
              ),
            ),
            const SizedBox(height: AppSizing.xs),
            Text(
              'Logs will appear here once members start tracking meals.',
              style: AppTypography.bodyS
                  .copyWith(color: context.textSecColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Navigation icon button ────────────────────────────────────────────────────

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _NavIconButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon,
          color: onPressed == null
              ? context.textTerColor
              : context.textPrimColor),
      onPressed: onPressed,
      iconSize: 22,
      padding: const EdgeInsets.all(AppSizing.xs),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 32, color: AppColors.error),
            ),
            const SizedBox(height: AppSizing.md),
            Text(
              message,
              style: AppTypography.bodyM
                  .copyWith(color: context.textSecColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand,
                side: const BorderSide(color: AppColors.brand),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History Tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatefulWidget {
  const _HistoryTab({required this.args});
  final MealPageArgs args;

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late DateTime _month;
  String? _selectedMemberId;
  Map<String, dynamic>? _data;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedMemberId = widget.args.myMemberId;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ds = sl<MealRemoteDataSource>();
      final result = await ds.getMemberMonthlyLogs(
        widget.args.flatId,
        _selectedMemberId!,
        _month.month,
        _month.year,
      );
      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ServerException ? e.message : 'Failed to load history';
        _loading = false;
      });
    }
  }

  void _prevMonth() {
    setState(() => _month = DateTime(_month.year, _month.month - 1));
    _load();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    setState(() => _month = DateTime(_month.year, _month.month + 1));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final now = DateTime.now();
    final isCurrentMonth =
        _month.year == now.year && _month.month == now.month;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizing.pagePadding, AppSizing.md, AppSizing.pagePadding, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Member selector (managers only see multi-member list)
                if (widget.args.canManage && widget.args.members.length > 1)
                  _MemberDropdown(
                    members: widget.args.members,
                    selectedId: _selectedMemberId,
                    onChanged: (id) {
                      setState(() => _selectedMemberId = id);
                      _load();
                    },
                  ),
                if (widget.args.canManage && widget.args.members.length > 1)
                  const SizedBox(height: AppSizing.md),

                // Month navigator
                Row(
                  children: [
                    IconButton(
                      onPressed: _prevMonth,
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: context.textSecColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Expanded(
                      child: Text(
                        _monthLabel(_month),
                        style: AppTypography.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: isCurrentMonth ? null : _nextMonth,
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: isCurrentMonth
                          ? context.textTerColor
                          : context.textSecColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizing.sm),
              ],
            ),
          ),
        ),

        if (_loading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          SliverFillRemaining(
            child: _ErrorView(message: _error!, onRetry: _load),
          )
        else if (_data != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizing.pagePadding),
              child: _CalendarView(
                month: _month,
                logs: _data!,
              ),
            ),
          )
        else
          const SliverFillRemaining(child: SizedBox.shrink()),
      ],
    );
  }

  String _monthLabel(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Member dropdown ────────────────────────────────────────────────────────

class _MemberDropdown extends StatelessWidget {
  const _MemberDropdown({
    required this.members,
    required this.selectedId,
    required this.onChanged,
  });

  final List<FlatMemberEntity> members;
  final String? selectedId;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizing.inputHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: context.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          style: AppTypography.bodyMedium.copyWith(
            color: context.textPrimColor,
          ),
          dropdownColor: context.cardColor,
          items: members.map((m) => DropdownMenuItem(
            value: m.flatMemberId,
            child: Text(m.name, style: AppTypography.bodyMedium),
          )).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Calendar view ──────────────────────────────────────────────────────────

class _CalendarView extends StatelessWidget {
  const _CalendarView({required this.month, required this.logs});

  final DateTime month;
  final Map<String, dynamic> logs;

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;

    final logsMap = <int, Map<String, dynamic>>{};
    final rawLogs = logs['logs'] as List? ?? [];
    for (final entry in rawLogs) {
      final e = entry as Map<String, dynamic>;
      final dateStr = e['date'] as String? ?? '';
      if (dateStr.isNotEmpty) {
        final day = DateTime.tryParse(dateStr)?.toUtc().day ?? 0;
        if (day > 0) logsMap[day] = e;
      }
    }

    final today = DateTime.now();
    final isCurrentMonth = month.year == today.year && month.month == today.month;

    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weekday headers
        Row(
          children: weekdays.map((d) => Expanded(
            child: Center(
              child: Text(
                d,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: AppSizing.xs),

        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.85,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (_, i) {
            if (i < firstWeekday) return const SizedBox.shrink();
            final day = i - firstWeekday + 1;
            final log = logsMap[day];
            return _CalendarCell(
              day: day,
              log: log,
              isToday: isCurrentMonth && day == today.day,
            );
          },
        ),

        const SizedBox(height: AppSizing.md),
        const _CalendarLegend(),
        const SizedBox(height: AppSizing.md),

        // Summary row
        if (logs['summary'] != null)
          _SummaryRow(summary: logs['summary'] as Map<String, dynamic>),
        const SizedBox(height: AppSizing.xl),
      ],
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.log,
    required this.isToday,
  });

  final int day;
  final Map<String, dynamic>? log;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final hasBreakfast = log?['breakfast'] == true;
    final hasLunch = log?['lunch'] == true;
    final hasDinner = log?['dinner'] == true;
    final guestCount = ((log?['breakfast_guests'] ?? 0) as num).toInt() +
        ((log?['lunch_guests'] ?? 0) as num).toInt() +
        ((log?['dinner_guests'] ?? 0) as num).toInt();

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
        border: isToday
            ? Border.all(color: AppColors.brand, width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isToday ? AppColors.brand : context.textPrimColor,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MealDot(active: hasBreakfast, color: const Color(0xFFF59E0B)),
              const SizedBox(width: 2),
              _MealDot(active: hasLunch, color: AppColors.primary),
              const SizedBox(width: 2),
              _MealDot(active: hasDinner, color: const Color(0xFF8B5CF6)),
            ],
          ),
          if (guestCount > 0) ...[
            const SizedBox(height: 2),
            Text(
              '+$guestCount',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 8,
                color: AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MealDot extends StatelessWidget {
  const _MealDot({required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? color : context.borderColor,
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _LegendItem(color: Color(0xFFF59E0B), label: 'Breakfast'),
        SizedBox(width: AppSizing.md),
        _LegendItem(color: AppColors.primary, label: 'Lunch'),
        SizedBox(width: AppSizing.md),
        _LegendItem(color: Color(0xFF8B5CF6), label: 'Dinner'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: context.textSecColor,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final breakfast = (summary['breakfast'] ?? 0) as num;
    final lunch = (summary['lunch'] ?? 0) as num;
    final dinner = (summary['dinner'] ?? 0) as num;
    final total = breakfast + lunch + dinner;

    return Container(
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: 'Breakfast',
            value: breakfast.toString(),
            color: const Color(0xFFF59E0B),
          ),
          const _Divider(),
          _SummaryItem(
            label: 'Lunch',
            value: lunch.toString(),
            color: AppColors.primary,
          ),
          const _Divider(),
          _SummaryItem(
            label: 'Dinner',
            value: dinner.toString(),
            color: const Color(0xFF8B5CF6),
          ),
          const _Divider(),
          _SummaryItem(
            label: 'Total',
            value: total.toString(),
            color: context.textPrimColor,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: context.textSecColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: context.borderColor,
    );
  }
}
