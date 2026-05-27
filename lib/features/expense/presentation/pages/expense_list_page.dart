import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/expense_summary_entity.dart';
import '../args/expense_detail_args.dart';
import '../args/record_expense_args.dart';
import '../bloc/expense_bloc.dart';
import '../widgets/expense_card.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({
    super.key,
    required this.flatId,
    required this.canManage,
    this.memberCount = 0,
  });

  final String flatId;
  final bool canManage;
  final int memberCount;

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  late int _selectedMonth;
  late int _selectedYear;
  String? _categoryFilter; // null = all, 'meal', 'household', 'fixed'
  bool? _approvedFilter; // null = all, true = approved, false = pending

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _loadExpenses();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadExpenses() {
    context.read<ExpenseBloc>().add(
          ExpensesLoadRequested(
            widget.flatId,
            month: _selectedMonth,
            year: _selectedYear,
            category: _categoryFilter,
            isApproved: _approvedFilter,
          ),
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<ExpenseBloc>().state;
      if (state is ExpenseListLoaded && state.hasMore && !state.isLoadingMore) {
        final currentPage =
            (state.pagination['page'] as int?) ?? 1;
        context.read<ExpenseBloc>().add(
              ExpensesLoadMoreRequested(
                widget.flatId,
                month: _selectedMonth,
                year: _selectedYear,
                category: _categoryFilter,
                isApproved: _approvedFilter,
                nextPage: currentPage + 1,
              ),
            );
      }
    }
  }

  void _previousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
    _loadExpenses();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedYear > now.year ||
        (_selectedYear == now.year && _selectedMonth >= now.month)) {
      return;
    }
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
    _loadExpenses();
  }

  String get _monthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[_selectedMonth - 1]} $_selectedYear';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(AppStrings.expenseListTitle,
            style: AppTypography.headlineMedium
                .copyWith(color: context.textPrimColor)),
      ),
      floatingActionButton: widget.canManage
          ? _GradientFab(
              onPressed: () => context
                  .push(
                    AppRoutes.recordExpense,
                    extra: RecordExpenseArgs(
                      flatId: widget.flatId,
                      memberCount: widget.memberCount,
                    ),
                  )
                  .then((_) {
                if (mounted) _loadExpenses();
              }),
            )
          : null,
      body: BlocConsumer<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseError) {
            AppSnackbar.error(context, state.message);
          }
          if (state is ExpenseActionSuccess) {
            AppSnackbar.success(context, state.message);
            _loadExpenses();
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.brand,
            onRefresh: () async {
              _loadExpenses();
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Month picker
                      _MonthPicker(
                        label: _monthLabel,
                        onPrevious: _previousMonth,
                        onNext: _nextMonth,
                        canGoNext: () {
                          final now = DateTime.now();
                          return !(_selectedYear == now.year &&
                              _selectedMonth >= now.month);
                        },
                      ),

                      // Summary cards
                      if (state is ExpenseListLoaded &&
                          state.summary != null) ...[
                        const SizedBox(height: AppSizing.md),
                        _SummaryRow(summary: state.summary!),
                      ],

                      const SizedBox(height: AppSizing.md),

                      // Filter chips
                      _FilterRow(
                        approvedFilter: _approvedFilter,
                        categoryFilter: _categoryFilter,
                        onApprovedFilterChanged: (val) {
                          setState(() => _approvedFilter = val);
                          _loadExpenses();
                        },
                        onCategoryFilterChanged: (val) {
                          setState(() => _categoryFilter = val);
                          _loadExpenses();
                        },
                      ),
                      const SizedBox(height: AppSizing.sm),
                    ],
                  ),
                ),

                // List content
                if (state is ExpenseListLoading)
                  const SliverToBoxAdapter(child: _ShimmerRows())
                else if (state is ExpenseError)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        state.message,
                        style: AppTypography.bodyMedium
                            .copyWith(color: context.textSecColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else if (state is ExpenseListLoaded) ...[
                  if (state.expenses.isEmpty)
                    const SliverFillRemaining(child: _EmptyState())
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizing.pagePadding),
                      sliver: SliverList.separated(
                        itemCount: state.expenses.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSizing.md),
                        itemBuilder: (context, index) {
                          final expense = state.expenses[index];
                          return ExpenseCard(
                            expense: expense,
                            onTap: () => context
                                .push(
                                  AppRoutes.expenseDetail,
                                  extra: ExpenseDetailArgs(
                                    flatId: widget.flatId,
                                    expenseId: expense.id,
                                    canManage: widget.canManage,
                                  ),
                                )
                                .then((_) {
                              if (mounted) _loadExpenses();
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
                                color: AppColors.brand),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: AppSizing.xxl)),
                  ],
                ],
              ],
            ),
          );
        },
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

// ── Month Picker ──────────────────────────────────────────────────────────────

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.canGoNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool Function() canGoNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.cardColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.pagePadding,
        vertical: AppSizing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded,
                color: context.textPrimColor),
            onPressed: onPrevious,
          ),
          Text(label,
              style: AppTypography.titleLarge
                  .copyWith(color: context.textPrimColor)),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: canGoNext()
                  ? context.textPrimColor
                  : context.textSecColor,
            ),
            onPressed: canGoNext() ? onNext : null,
          ),
        ],
      ),
    );
  }
}

// ── Summary Row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});
  final ExpenseSummaryEntity summary;

  static const Color _mealColor = Color(0xFFF57C00);
  static const Color _householdColor = Color(0xFF7B1FA2);
  static const Color _fixedColor = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
      child: Row(
        children: [
          _SummaryCard(
            label: 'Meal',
            amount: summary.meal.approvedTotal,
            color: _mealColor,
            icon: Icons.restaurant_outlined,
          ),
          const SizedBox(width: AppSizing.sm),
          _SummaryCard(
            label: 'Household',
            amount: summary.household.approvedTotal,
            color: _householdColor,
            icon: Icons.home_outlined,
          ),
          const SizedBox(width: AppSizing.sm),
          _SummaryCard(
            label: 'Fixed',
            amount: summary.fixed.approvedTotal,
            color: _fixedColor,
            icon: Icons.receipt_long_outlined,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: AppSizing.iconSm + 4),
            const SizedBox(height: AppSizing.xs),
            Text(
              '৳${amount.toStringAsFixed(0)}',
              style: AppTypography.titleMedium.copyWith(color: color),
            ),
            Text(label, style: AppTypography.labelSmall),
          ],
        ),
      ),
    );
  }
}

// ── Filter Row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.approvedFilter,
    required this.categoryFilter,
    required this.onApprovedFilterChanged,
    required this.onCategoryFilterChanged,
  });

  final bool? approvedFilter;
  final String? categoryFilter;
  final void Function(bool?) onApprovedFilterChanged;
  final void Function(String?) onCategoryFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            selected: approvedFilter == null,
            onTap: () => onApprovedFilterChanged(null),
          ),
          const SizedBox(width: AppSizing.xs),
          _Chip(
            label: 'Pending',
            selected: approvedFilter == false,
            onTap: () => onApprovedFilterChanged(false),
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSizing.xs),
          _Chip(
            label: 'Approved',
            selected: approvedFilter == true,
            onTap: () => onApprovedFilterChanged(true),
            color: AppColors.success,
          ),
          const SizedBox(width: AppSizing.md),
          _Chip(
            label: 'Meal',
            selected: categoryFilter == 'meal',
            onTap: () => onCategoryFilterChanged(
                categoryFilter == 'meal' ? null : 'meal'),
            color: const Color(0xFFF57C00),
          ),
          const SizedBox(width: AppSizing.xs),
          _Chip(
            label: 'Household',
            selected: categoryFilter == 'household',
            onTap: () => onCategoryFilterChanged(
                categoryFilter == 'household' ? null : 'household'),
            color: const Color(0xFF7B1FA2),
          ),
          const SizedBox(width: AppSizing.xs),
          _Chip(
            label: 'Fixed',
            selected: categoryFilter == 'fixed',
            onTap: () => onCategoryFilterChanged(
                categoryFilter == 'fixed' ? null : 'fixed'),
            color: const Color(0xFF1565C0),
          ),
        ],
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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.brand;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.1)
              : context.cardColor,
          borderRadius: BorderRadius.circular(AppSizing.radiusFull),
          border: Border.all(
            color: selected ? activeColor : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? activeColor : context.textSecColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
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
              Icons.receipt_long_outlined,
              size: 36,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: AppSizing.md),
          Text(
            AppStrings.noExpensesRecorded,
            style: AppTypography.bodyMedium
                .copyWith(color: context.textSecColor),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer Placeholder Rows ──────────────────────────────────────────────────

class _ShimmerRows extends StatefulWidget {
  const _ShimmerRows();

  @override
  State<_ShimmerRows> createState() => _ShimmerRowsState();
}

class _ShimmerRowsState extends State<_ShimmerRows>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.pagePadding, vertical: AppSizing.sm),
        child: Column(
          children: List.generate(
            3,
            (_) => Opacity(
              opacity: _anim.value,
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSizing.md),
                padding: const EdgeInsets.all(AppSizing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface200,
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface300,
                        borderRadius:
                            BorderRadius.circular(AppSizing.radiusMd),
                      ),
                    ),
                    const SizedBox(width: AppSizing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.surface300,
                                borderRadius: BorderRadius.circular(
                                    AppSizing.radiusFull),
                              )),
                          const SizedBox(height: AppSizing.xs),
                          Container(
                              height: 10,
                              width: 120,
                              decoration: BoxDecoration(
                                color: AppColors.surface300,
                                borderRadius: BorderRadius.circular(
                                    AppSizing.radiusFull),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizing.md),
                    Container(
                        height: 14,
                        width: 60,
                        decoration: BoxDecoration(
                          color: AppColors.surface300,
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusFull),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
