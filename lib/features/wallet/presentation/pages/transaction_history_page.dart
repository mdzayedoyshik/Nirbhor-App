import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../bloc/transactions/transactions_bloc.dart';
import '../widgets/transaction_row.dart';

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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
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
              Expanded(child: _buildList(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, TransactionsState state) {
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
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSizing.md),
            TextButton(onPressed: _load, child: Text(AppStrings.retry)),
          ],
        ),
      );
    }
    if (state is! TransactionsLoaded) return const SizedBox.shrink();

    if (state.transactions.isEmpty) {
      return Center(
        child: Text('No transactions found.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        _load();
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.pagePadding, vertical: AppSizing.sm),
        itemCount:
            state.transactions.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.transactions.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSizing.md),
              child:
                  Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }
          return Column(
            children: [
              TransactionRow(transaction: state.transactions[index]),
              if (index < state.transactions.length - 1)
                const Divider(height: 1, color: AppColors.divider),
            ],
          );
        },
      ),
    );
  }
}

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
      color: AppColors.background,
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
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                backgroundColor: AppColors.surface,
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
