import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../bloc/transactions/transactions_bloc.dart';
import '../widgets/transaction_row.dart';
import '../../domain/entities/transaction_entity.dart';

// ── List item model ───────────────────────────────────────────────────────────

sealed class _ListItem {}

class _DateHeader extends _ListItem {
  _DateHeader(this.label);
  final String label;
}

class _TxItem extends _ListItem {
  _TxItem(this.tx);
  final TransactionEntity tx;
}

// ── Date grouping helper ──────────────────────────────────────────────────────

List<_ListItem> _buildGrouped(List<TransactionEntity> txs) {
  if (txs.isEmpty) return [];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final items = <_ListItem>[];
  DateTime? currentDay;

  for (final tx in txs) {
    DateTime dt;
    try {
      dt = DateTime.parse(tx.createdAt).toLocal();
    } catch (_) {
      dt = DateTime.now();
    }
    final txDay = DateTime(dt.year, dt.month, dt.day);

    if (txDay != currentDay) {
      currentDay = txDay;

      final String label;
      if (txDay == today) {
        label = 'Today';
      } else if (txDay == yesterday) {
        label = 'Yesterday';
      } else if (txDay.year == now.year) {
        label = '${txDay.day} ${months[txDay.month - 1]}';
      } else {
        label = '${txDay.day} ${months[txDay.month - 1]} ${txDay.year}';
      }

      items.add(_DateHeader(label));
    }

    items.add(_TxItem(tx));
  }

  return items;
}

// ── Page ──────────────────────────────────────────────────────────────────────

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key, required this.flatId});

  final String flatId;

  @override
  State<TransactionHistoryPage> createState() =>
      _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final _scrollController = ScrollController();
  String? _typeFilter;

  static const _filters = [
    (label: 'All', value: null),
    (label: 'Deposits', value: 'deposit'),
    (label: 'Deductions', value: 'deduction'),
    (label: 'Refunds', value: 'refund'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  void _load() {
    context.read<TransactionsBloc>().add(
          TransactionsLoadRequested(widget.flatId, type: _typeFilter),
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context
          .read<TransactionsBloc>()
          .add(TransactionsLoadMoreRequested(widget.flatId));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionsBloc, TransactionsState>(
      listener: (context, state) {
        if (state is TransactionsError) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            backgroundColor: context.bgColor,
            elevation: 0,
            title: Text(AppStrings.transactionHistoryTitle,
                style: AppTypography.headlineMedium),
          ),
          body: Column(
            children: [
              _FilterBar(
                selected: _typeFilter,
                filters: _filters,
                onSelect: (v) {
                  setState(() => _typeFilter = v);
                  _load();
                },
              ),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TransactionsState state) {
    if (state is TransactionsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state is TransactionsError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.message,
                style: AppTypography.bodyMedium
                    .copyWith(color: context.textSecColor)),
            const SizedBox(height: AppSizing.md),
            TextButton(onPressed: _load, child: Text(AppStrings.retry)),
          ],
        ),
      );
    }

    if (state is! TransactionsLoaded) return const SizedBox.shrink();

    if (state.transactions.isEmpty) {
      return Center(
        child: Text(
          'No transactions found.',
          style:
              AppTypography.bodyMedium.copyWith(color: context.textSecColor),
        ),
      );
    }

    final grouped = _buildGrouped(state.transactions);
    final itemCount = grouped.length + (state.isLoadingMore ? 1 : 0);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        _load();
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          left: AppSizing.pagePadding,
          right: AppSizing.pagePadding,
          bottom: AppSizing.xl,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Load-more spinner pinned at the bottom
          if (index == grouped.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSizing.md),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary)),
            );
          }

          final item = grouped[index];

          if (item is _DateHeader) {
            return _DateHeaderTile(label: item.label);
          }

          return TransactionRow(transaction: (item as _TxItem).tx);
        },
      ),
    );
  }
}

// ── Date header tile ──────────────────────────────────────────────────────────

class _DateHeaderTile extends StatelessWidget {
  const _DateHeaderTile({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizing.lg, bottom: AppSizing.xs),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: context.textTerColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.filters,
    required this.onSelect,
  });

  final String? selected;
  final List<({String label, String? value})> filters;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.bgColor,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.pagePadding, vertical: AppSizing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = selected == f.value;
            return Padding(
              padding: const EdgeInsets.only(right: AppSizing.sm),
              child: ChoiceChip(
                label: Text(f.label),
                selected: isSelected,
                onSelected: (_) => onSelect(f.value),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                labelStyle: AppTypography.labelLarge.copyWith(
                  color: isSelected ? AppColors.primary : context.textPrimColor,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : context.borderColor,
                ),
                backgroundColor: context.cardColor,
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
