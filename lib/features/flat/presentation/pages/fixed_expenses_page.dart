import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../wallet/presentation/bloc/payment_hints/payment_hints_bloc.dart';
import '../../domain/entities/fixed_expense_entity.dart';
import '../bloc/fixed_expenses_bloc.dart';
import '../bloc/flat_bloc.dart';
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
    context.read<FixedExpensesBloc>().add(FixedExpensesLoadRequested(widget.flatId));
    if (widget.canManage) {
      context.read<PaymentHintsBloc>().add(PaymentHintsLoadRequested(widget.flatId));
    }
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final bloc = context.read<FixedExpensesBloc>();
    await AppBottomSheet.show(
      context: context,
      title: AppStrings.addExpenseLabel,
      child: BlocProvider.value(
        value: bloc,
        child: _ExpenseForm(flatId: widget.flatId),
      ),
    );
  }

  Future<void> _showEditSheet(
    BuildContext context,
    FixedExpenseEntity expense,
  ) async {
    final bloc = context.read<FixedExpensesBloc>();
    await AppBottomSheet.show(
      context: context,
      title: AppStrings.editExpenseTitle,
      child: BlocProvider.value(
        value: bloc,
        child: _ExpenseForm(flatId: widget.flatId, expense: expense),
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
      context.read<FixedExpensesBloc>().add(
        FixedExpenseDeleteRequested(
          flatId: widget.flatId,
          expenseId: expense.id,
        ),
      );
    }
  }

  Future<void> _showHintsSheet(BuildContext context) async {
    final hintsBloc = context.read<PaymentHintsBloc>();
    final currentState = hintsBloc.state;

    final mealCtrl = TextEditingController(
      text: currentState is PaymentHintsLoaded
          ? currentState.hints.suggestedMealAmount.toStringAsFixed(0)
          : currentState is PaymentHintsUpdateSuccess
              ? currentState.hints.suggestedMealAmount.toStringAsFixed(0)
              : '',
    );
    final householdCtrl = TextEditingController(
      text: currentState is PaymentHintsLoaded
          ? currentState.hints.suggestedHouseholdAmount.toStringAsFixed(0)
          : currentState is PaymentHintsUpdateSuccess
              ? currentState.hints.suggestedHouseholdAmount.toStringAsFixed(0)
              : '',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizing.radiusLg)),
      ),
      builder: (sheetCtx) => BlocProvider.value(
        value: hintsBloc,
        child: _HintsSheet(
          flatId: widget.flatId,
          mealCtrl: mealCtrl,
          householdCtrl: householdCtrl,
        ),
      ),
    );

    mealCtrl.dispose();
    householdCtrl.dispose();
  }

  Future<void> _redistribute(BuildContext context) async {
    final flatState = sl<FlatBloc>().state;
    final members = (flatState is FlatLoaded)
        ? flatState.flat.activeMembers
        : <dynamic>[];

    if (members.isEmpty) {
      AppSnackbar.error(context, 'No active members found.');
      return;
    }

    // Get current total from the loaded state
    double totalFixed = 0;
    final state = context.read<FixedExpensesBloc>().state;
    if (state is FixedExpensesLoaded) {
      totalFixed = state.total;
    } else if (state is FixedExpensesActionSuccess) {
      totalFixed = state.total;
    }

    if (totalFixed <= 0) {
      AppSnackbar.error(context, 'No fixed expenses to redistribute.');
      return;
    }

    // Build controllers for each member
    final double equalShare =
        double.parse((totalFixed / members.length).toStringAsFixed(2));
    final controllers = <String, TextEditingController>{};
    for (final m in members) {
      controllers[m.flatMemberId] = TextEditingController(
        text: m.fixedContribution > 0
            ? m.fixedContribution.toStringAsFixed(0)
            : equalShare.toStringAsFixed(0),
      );
    }

    final bloc = context.read<FixedExpensesBloc>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizing.radiusLg)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          double currentTotal() {
            return controllers.values.fold(
              0.0,
              (s, c) => s + (double.tryParse(c.text.trim()) ?? 0),
            );
          }

          void resetToEqual() {
            final totalCents = (totalFixed * 100).round();
            final perCents = totalCents ~/ members.length;
            final remainderCents = totalCents - perCents * members.length;
            for (int i = 0; i < members.length; i++) {
              final shareCents = perCents + (i == 0 ? remainderCents : 0);
              controllers[members[i].flatMemberId]?.text =
                  (shareCents / 100).toStringAsFixed(0);
            }
            setSheetState(() {});
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizing.pagePadding,
              AppSizing.md,
              AppSizing.pagePadding,
              MediaQuery.of(context).viewInsets.bottom + AppSizing.pagePadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSizing.md),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius:
                          BorderRadius.circular(AppSizing.radiusFull),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.redistributeLabel,
                        style: AppTypography.headlineSmall),
                    TextButton(
                      onPressed: resetToEqual,
                      child: Text(
                        'Equal Split',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Total fixed: ৳${totalFixed.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizing.md),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: members.map((m) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSizing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name,
                                        style: AppTypography.titleMedium),
                                    Text(
                                      m.role == 'manager'
                                          ? 'Manager'
                                          : m.role == 'co-manager'
                                              ? 'Co-manager'
                                              : 'Member',
                                      style: AppTypography.labelSmall
                                          .copyWith(
                                              color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSizing.sm),
                              Expanded(
                                flex: 2,
                                child: StatefulBuilder(
                                  builder: (ctx, setSub) {
                                    return TextField(
                                      controller:
                                          controllers[m.flatMemberId],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        prefix: const Text('৳ '),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 8),
                                        isDense: true,
                                      ),
                                      style: AppTypography.titleMedium,
                                      onChanged: (_) =>
                                          setSheetState(() {}),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizing.sm),
                // Running total indicator
                Builder(builder: (_) {
                  final total = currentTotal();
                  final diff = (total - totalFixed).abs();
                  final isValid = diff < 0.1;
                  return Container(
                    padding: const EdgeInsets.all(AppSizing.sm),
                    decoration: BoxDecoration(
                      color: isValid
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSizing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isValid ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                          color: isValid ? AppColors.success : AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: AppSizing.xs),
                        Text(
                          isValid
                              ? 'Total: ৳${total.toStringAsFixed(0)} ✓'
                              : 'Total: ৳${total.toStringAsFixed(0)} — must equal ৳${totalFixed.toStringAsFixed(0)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: isValid
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppSizing.md),
                AppButton(
                  label: 'Apply Distribution',
                  onPressed: () {
                    final total = currentTotal();
                    if ((total - totalFixed).abs() > 0.1) {
                      AppSnackbar.error(
                        sheetCtx,
                        'Total must equal ৳${totalFixed.toStringAsFixed(0)}',
                      );
                      return;
                    }
                    final contributions = members
                        .map((m) => {
                              'flat_member_id': m.flatMemberId,
                              'amount': double.tryParse(
                                      controllers[m.flatMemberId]
                                              ?.text
                                              .trim() ??
                                          '0') ??
                                  0.0,
                            })
                        .toList();
                    Navigator.pop(sheetCtx);
                    bloc.add(FixedExpensesRedistributeRequested(
                      widget.flatId,
                      contributions: contributions,
                    ));
                  },
                  variant: AppButtonVariant.primary,
                  fullWidth: true,
                ),
              ],
            ),
          );
        },
      ),
    );

    // Dispose controllers
    for (final c in controllers.values) {
      c.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.fixedExpensesTitle,
          style: AppTypography.titleLarge,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (widget.canManage)
            IconButton(
              icon: const Icon(
                Icons.balance_outlined,
                color: AppColors.textPrimary,
              ),
              tooltip: AppStrings.redistributeLabel,
              onPressed: () => _redistribute(context),
            ),
        ],
      ),
      body: BlocConsumer<FixedExpensesBloc, FixedExpensesState>(
        listenWhen: (_, curr) =>
            curr is FixedExpensesActionSuccess ||
            curr is FixedExpensesActionError,
        listener: (context, state) {
          if (state is FixedExpensesActionSuccess && !state.isFormAction) {
            AppSnackbar.success(context, state.message);
          }
          if (state is FixedExpensesActionError) {
            AppSnackbar.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is FixedExpensesLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is FixedExpensesLoadError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: AppSizing.iconLg,
                  ),
                  const SizedBox(height: AppSizing.md),
                  Text(state.message, style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSizing.md),
                  TextButton(
                    onPressed: () => context.read<FixedExpensesBloc>().add(
                      FixedExpensesLoadRequested(widget.flatId),
                    ),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            );
          }

          final isActionLoading =
              state is FixedExpensesActionInProgress && !state.isFormAction;

          List<FixedExpenseEntity> expenses = [];
          double total = 0;

          if (state is FixedExpensesLoaded) {
            expenses = state.expenses;
            total = state.total;
          } else if (state is FixedExpensesActionInProgress) {
            expenses = state.expenses;
            total = state.total;
          } else if (state is FixedExpensesActionError) {
            expenses = state.expenses;
            total = state.total;
          } else if (state is FixedExpensesActionSuccess) {
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
                      borderRadius:
                          BorderRadius.circular(AppSizing.radiusLg),
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
                                color:
                                    AppColors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              '৳${total.toStringAsFixed(0)}',
                              style:
                                  AppTypography.headlineMedium.copyWith(
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
                              Icons.receipt_long_outlined,
                              color: AppColors.textHint,
                              size: AppSizing.iconXl,
                            ),
                            const SizedBox(height: AppSizing.md),
                            Text(
                              'No Expenses Added',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSizing.xs),
                            Text(
                              'Add shared expenses like rent or utilities\nto track each member\'s contribution.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
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

                  // ── Payment Hints section (manager only) ──
                  if (widget.canManage) ...[
                    const SizedBox(height: AppSizing.lg),
                    _HintsSectionCard(
                      onEdit: () => _showHintsSheet(context),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
              if (isActionLoading)
                Positioned.fill(
                  child: Container(
                    color: AppColors.white.withValues(alpha: 0.5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
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

// ── Payment Hints card ───────────────────────────────────────────────────────

class _HintsSectionCard extends StatelessWidget {
  const _HintsSectionCard({required this.onEdit});
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentHintsBloc, PaymentHintsState>(
      builder: (context, state) {
        final hints = switch (state) {
          PaymentHintsLoaded(hints: final h) => h,
          PaymentHintsActionLoading(hints: final h) => h,
          PaymentHintsUpdateSuccess(hints: final h) => h,
          PaymentHintsError(hints: final h) when h != null => h,
          _ => null,
        };
        final isLoading = state is PaymentHintsLoading;

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
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    ),
                    child: const Icon(Icons.savings_outlined,
                        size: 18, color: AppColors.brand),
                  ),
                  const SizedBox(width: AppSizing.sm),
                  Expanded(
                    child: Text(
                      AppStrings.paymentHintsTitle,
                      style: AppTypography.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                    tooltip: 'Edit hints',
                  ),
                ],
              ),
              const SizedBox(height: AppSizing.xs),
              Text(
                AppStrings.paymentHintsHelperNote,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSizing.md),
              if (isLoading)
                const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.brand),
                  ),
                )
              else if (hints != null) ...[
                _HintRow(
                  icon: Icons.restaurant_outlined,
                  label: 'Meal estimate / person',
                  value: '৳${hints.suggestedMealAmount.toStringAsFixed(0)}',
                ),
                const SizedBox(height: AppSizing.xs),
                _HintRow(
                  icon: Icons.home_outlined,
                  label: 'Household estimate',
                  value:
                      '৳${hints.suggestedHouseholdAmount.toStringAsFixed(0)}',
                ),
              ] else
                Text(
                  'Tap edit to set hints',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textHint),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: AppSizing.xs),
        Expanded(
          child: Text(label,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ),
        Text(value,
            style: AppTypography.titleMedium.copyWith(color: AppColors.brand)),
      ],
    );
  }
}

// ── Hints edit sheet ─────────────────────────────────────────────────────────

class _HintsSheet extends StatelessWidget {
  const _HintsSheet({
    required this.flatId,
    required this.mealCtrl,
    required this.householdCtrl,
  });
  final String flatId;
  final TextEditingController mealCtrl;
  final TextEditingController householdCtrl;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentHintsBloc, PaymentHintsState>(
      listenWhen: (_, curr) =>
          curr is PaymentHintsUpdateSuccess || curr is PaymentHintsError,
      listener: (context, state) {
        if (state is PaymentHintsUpdateSuccess) {
          Navigator.of(context).pop();
          AppSnackbar.success(context, AppStrings.paymentHintsUpdatedMsg);
        }
        if (state is PaymentHintsError) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final isSaving = state is PaymentHintsActionLoading;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSizing.pagePadding,
            AppSizing.md,
            AppSizing.pagePadding,
            MediaQuery.of(context).viewInsets.bottom + AppSizing.pagePadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius:
                        BorderRadius.circular(AppSizing.radiusFull),
                  ),
                ),
              ),
              Text(AppStrings.paymentHintsTitle,
                  style: AppTypography.headlineSmall),
              const SizedBox(height: AppSizing.xs),
              Text(
                AppStrings.paymentHintsHelperNote,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSizing.md),
              AppTextField(
                controller: mealCtrl,
                label: AppStrings.suggestedMealLabel,
                hint: '0',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.restaurant_outlined,
                    color: AppColors.textSecondary, size: 20),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSizing.md),
              AppTextField(
                controller: householdCtrl,
                label: AppStrings.suggestedHouseholdLabel,
                hint: '0',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.home_outlined,
                    color: AppColors.textSecondary, size: 20),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSizing.lg),
              AppButton(
                label: AppStrings.saveChanges,
                loading: isSaving,
                onPressed: isSaving
                    ? null
                    : () {
                        final meal =
                            double.tryParse(mealCtrl.text.trim()) ?? 0;
                        final household =
                            double.tryParse(householdCtrl.text.trim()) ?? 0;
                        context.read<PaymentHintsBloc>().add(
                              PaymentHintsUpdateRequested(
                                flatId: flatId,
                                suggestedMealAmount: meal,
                                suggestedHouseholdAmount: household,
                              ),
                            );
                      },
                variant: AppButtonVariant.primary,
                fullWidth: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Expense Form ────────────────────────────────────────────────────────────

class _ExpenseForm extends StatefulWidget {
  final String flatId;
  final FixedExpenseEntity? expense;

  const _ExpenseForm({required this.flatId, this.expense});

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _typeCtrl;
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _typeCtrl = TextEditingController(text: widget.expense?.expenseType ?? '');
    _amountCtrl = TextEditingController(
      text: widget.expense != null
          ? widget.expense!.amount.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final type = _typeCtrl.text.trim();
    final amount = double.parse(_amountCtrl.text.trim());

    if (widget.expense != null) {
      context.read<FixedExpensesBloc>().add(FixedExpenseUpdateRequested(
        flatId: widget.flatId,
        expenseId: widget.expense!.id,
        expenseType: type,
        amount: amount,
      ));
    } else {
      context.read<FixedExpensesBloc>().add(FixedExpenseAddRequested(
        flatId: widget.flatId,
        expenseType: type,
        amount: amount,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FixedExpensesBloc, FixedExpensesState>(
      listenWhen: (_, curr) =>
          curr is FixedExpensesActionSuccess && curr.isFormAction,
      listener: (context, state) {
        if (state is FixedExpensesActionSuccess && state.isFormAction) {
          Navigator.of(context).pop();
          AppSnackbar.success(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is FixedExpensesActionInProgress;
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _typeCtrl,
                label: AppStrings.expenseTypeLabel,
                hint: AppStrings.expenseTypeHint,
                prefixIcon: const Icon(
                  Icons.receipt_outlined,
                  color: AppColors.textSecondary,
                ),
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
                  child: Text(
                    '৳',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a positive amount';
                  return null;
                },
                onSubmitted: (_) => _submit(context),
              ),
              const SizedBox(height: AppSizing.lg),
              AppButton(
                label: widget.expense != null
                    ? 'Save Changes'
                    : AppStrings.addExpenseLabel,
                loading: isLoading,
                onPressed: isLoading ? null : () => _submit(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
