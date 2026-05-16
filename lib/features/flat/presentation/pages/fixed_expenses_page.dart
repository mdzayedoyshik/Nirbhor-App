import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/fixed_expense_entity.dart';
import '../cubit/fixed_expenses_cubit.dart';
import '../widgets/expense_tile.dart';

class FixedExpensesPage extends StatefulWidget {
  final String flatId;
  final bool canManage;

  const FixedExpensesPage({
    super.key,
    required this.flatId,
    required this.canManage,
  });

  @override
  State<FixedExpensesPage> createState() => _FixedExpensesPageState();
}

class _FixedExpensesPageState extends State<FixedExpensesPage> {
  @override
  void initState() {
    super.initState();
    context.read<FixedExpensesCubit>().load(widget.flatId);
  }

  Future<void> _showAddSheet(BuildContext context) async {
    await AppBottomSheet.show(
      context: context,
      title: AppStrings.addExpenseLabel,
      child: _ExpenseForm(
        onSubmit: (type, amount) async {
          final ok = await context.read<FixedExpensesCubit>().add(
                flatId: widget.flatId,
                expenseType: type,
                amount: amount,
              );
          if (ok && context.mounted) {
            Navigator.of(context).pop();
            AppSnackbar.success(context, AppStrings.expenseAddedMsg);
          }
        },
      ),
    );
  }

  Future<void> _showEditSheet(
    BuildContext context,
    FixedExpenseEntity expense,
  ) async {
    await AppBottomSheet.show(
      context: context,
      title: AppStrings.editExpenseTitle,
      child: _ExpenseForm(
        initialType: expense.expenseType,
        initialAmount: expense.amount,
        onSubmit: (type, amount) async {
          final ok = await context.read<FixedExpensesCubit>().update(
                flatId: widget.flatId,
                expenseId: expense.id,
                expenseType: type,
                amount: amount,
              );
          if (ok && context.mounted) {
            Navigator.of(context).pop();
            AppSnackbar.success(context, AppStrings.expenseUpdatedMsg);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FixedExpenseEntity expense,
  ) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: AppStrings.deleteExpenseConfirmTitle,
      message: AppStrings.deleteExpenseConfirmMsg,
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed == true && context.mounted) {
      await context.read<FixedExpensesCubit>().delete(
            flatId: widget.flatId,
            expenseId: expense.id,
          );
      if (context.mounted) {
        AppSnackbar.success(context, AppStrings.expenseDeletedMsg);
      }
    }
  }

  Future<void> _redistribute(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Redistribute Equally?',
      message:
          'This will split all fixed expenses equally among active members.',
      confirmLabel: AppStrings.redistributeLabel,
    );
    if (confirmed == true && context.mounted) {
      await context.read<FixedExpensesCubit>().redistribute(widget.flatId);
      if (context.mounted) {
        AppSnackbar.success(context, AppStrings.redistributedMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.fixedExpensesTitle,
            style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (widget.canManage)
            IconButton(
              icon: const Icon(Icons.balance_outlined,
                  color: AppColors.textPrimary),
              tooltip: AppStrings.redistributeLabel,
              onPressed: () => _redistribute(context),
            ),
        ],
      ),
      body: BlocConsumer<FixedExpensesCubit, FixedExpensesState>(
        listener: (context, state) {
          if (state is FixedExpensesError) {
            AppSnackbar.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is FixedExpensesLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final isFormLoading = state is FixedExpensesFormLoading;

          List<FixedExpenseEntity> expenses = [];
          double total = 0;
          if (state is FixedExpensesLoaded) {
            expenses = state.expenses;
            total = state.total;
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSizing.pagePadding),
                children: [
                  // Total summary card
                  Container(
                    padding: const EdgeInsets.all(AppSizing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.white,
                            size: AppSizing.iconMd,
                          ),
                        ),
                        const SizedBox(width: AppSizing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.totalExpenses,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              '৳${total.toStringAsFixed(0)}',
                              style: AppTypography.headlineMedium.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizing.lg),
                  if (expenses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSizing.xl),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.receipt_outlined,
                              color: AppColors.textHint,
                              size: AppSizing.iconXl,
                            ),
                            const SizedBox(height: AppSizing.md),
                            Text(
                              AppStrings.noExpenses,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...expenses.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSizing.sm),
                        child: ExpenseTile(
                          expense: e,
                          canManage: widget.canManage,
                          onEdit: () => _showEditSheet(context, e),
                          onDelete: () => _confirmDelete(context, e),
                        ),
                      ),
                    ),
                  const SizedBox(height: 80), // FAB padding
                ],
              ),
              if (isFormLoading)
                Positioned.fill(
                  child: Container(
                    color: AppColors.white.withValues(alpha: 0.5),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add),
              label: Text(
                AppStrings.addExpenseLabel,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            )
          : null,
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  final String? initialType;
  final double? initialAmount;
  final Future<void> Function(String type, double amount) onSubmit;

  const _ExpenseForm({
    this.initialType,
    this.initialAmount,
    required this.onSubmit,
  });

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _typeCtrl;
  late final TextEditingController _amountCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _typeCtrl = TextEditingController(text: widget.initialType ?? '');
    _amountCtrl = TextEditingController(
      text: widget.initialAmount != null
          ? widget.initialAmount!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        _typeCtrl.text.trim(),
        double.parse(_amountCtrl.text.trim()),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _typeCtrl,
            label: AppStrings.expenseTypeLabel,
            hint: AppStrings.expenseTypeHint,
            prefixIcon: const Icon(Icons.receipt_outlined,
                color: AppColors.textSecondary),
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppSizing.md),
          AppTextField(
            controller: _amountCtrl,
            label: AppStrings.amountLabel,
            hint: AppStrings.amountHint,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            prefixIcon: const Padding(
              padding: EdgeInsets.all(AppSizing.sm + 4),
              child: Text('৳',
                  style: TextStyle(
                      fontSize: 18, color: AppColors.textSecondary)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final n = double.tryParse(v.trim());
              if (n == null || n <= 0) return 'Enter a positive amount';
              return null;
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSizing.lg),
          AppButton(
            label: widget.initialType != null
                ? 'Save Changes'
                : AppStrings.addExpenseLabel,
            loading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
