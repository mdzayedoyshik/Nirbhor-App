import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/expense_entity.dart';
import '../args/edit_expense_args.dart';
import '../bloc/expense_bloc.dart';

class ExpenseDetailPage extends StatefulWidget {
  const ExpenseDetailPage({
    super.key,
    required this.flatId,
    required this.expenseId,
    required this.canManage,
  });

  final String flatId;
  final String expenseId;
  final bool canManage;

  @override
  State<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(
          ExpenseDetailRequested(widget.flatId, widget.expenseId),
        );
  }

  static const Color _mealColor = Color(0xFFF57C00);
  static const Color _householdColor = Color(0xFF7B1FA2);
  static const Color _fixedColor = Color(0xFF1565C0);

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'meal':
        return _mealColor;
      case 'household':
        return _householdColor;
      case 'fixed':
        return _fixedColor;
      default:
        return AppColors.textSecondary;
    }
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'meal':
        return 'Meal';
      case 'household':
        return 'Household';
      case 'fixed':
        return 'Fixed';
      default:
        return cat;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _confirmApprove(BuildContext context, ExpenseEntity expense) {
    final category = _categoryLabel(expense.expenseCategory);
    String message;
    switch (expense.expenseCategory) {
      case 'meal':
        message =
            'Approving this will deduct ৳${expense.amount.toStringAsFixed(0)} from the flat wallet and update the meal pool.';
        break;
      case 'household':
        message =
            'Approving this will deduct ৳${expense.amount.toStringAsFixed(0)} from the flat wallet and split equally among active members.';
        break;
      default:
        message =
            'Approving this will deduct ৳${expense.amount.toStringAsFixed(0)} from the flat wallet.';
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Approve $category Expense?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ExpenseBloc>().add(
                    ExpenseApproveRequested(
                        widget.flatId, widget.expenseId),
                  );
            },
            child: Text(
              AppStrings.approveLabel,
              style: const TextStyle(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.deleteExpenseConfirmTitle),
        content: const Text(AppStrings.deleteExpenseConfirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ExpenseBloc>().add(
                    ExpenseDeleteRequested(
                        widget.flatId, widget.expenseId),
                  );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveResult(
      BuildContext context, Map<String, dynamic>? result) {
    if (result == null) return;
    final type = result['type'] as String? ?? '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Expense Approved'),
        content: _ApproveResultContent(result: result, type: type),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        if (state is ExpenseError) {
          AppSnackbar.error(context, state.message);
        }
        if (state is ExpenseActionSuccess) {
          if (state.approveResult != null) {
            _showApproveResult(context, state.approveResult);
          } else if (state.message == 'Expense deleted.') {
            AppSnackbar.success(context, state.message);
            context.pop();
          } else {
            AppSnackbar.success(context, state.message);
            // Reload detail
            context.read<ExpenseBloc>().add(
                  ExpenseDetailRequested(widget.flatId, widget.expenseId),
                );
          }
        }
      },
      builder: (context, state) {
        ExpenseEntity? expense;
        if (state is ExpenseDetailLoaded) expense = state.expense;

        final isLoading =
            state is ExpenseDetailLoading || state is ExpenseActionLoading;

        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            backgroundColor: context.bgColor,
            elevation: 0,
            title: Text(AppStrings.expenseDetailTitle,
                style: AppTypography.headlineMedium),
            actions: [
              if (expense != null &&
                  !expense.isApproved &&
                  widget.canManage)
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      color: context.textPrimColor),
                  onPressed: () {
                    final bloc = context.read<ExpenseBloc>();
                    context
                        .push(
                          AppRoutes.editExpense,
                          extra: EditExpenseArgs(
                            flatId: widget.flatId,
                            expense: expense!,
                          ),
                        )
                        .then((_) {
                      if (mounted) {
                        bloc.add(ExpenseDetailRequested(
                            widget.flatId, widget.expenseId));
                      }
                    });
                  },
                ),
            ],
          ),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : expense == null
                  ? Center(
                      child: Text(
                        'Expense not found.',
                        style: AppTypography.bodyMedium
                            .copyWith(color: context.textSecColor),
                      ),
                    )
                  : _buildContent(context, expense),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ExpenseEntity expense) {
    final color = _categoryColor(expense.expenseCategory);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Approved banner
          if (expense.isApproved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizing.md),
              margin: const EdgeInsets.only(bottom: AppSizing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: AppSizing.sm),
                  Expanded(
                    child: Text(
                      expense.approvedByName != null &&
                              expense.approvedAt != null
                          ? 'Approved by ${expense.approvedByName} on ${_formatDate(expense.approvedAt!)}'
                          : 'Approved',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),

          // Main card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizing.lg),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(AppSizing.radiusLg),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                  ),
                  child: Icon(
                    expense.isMeal
                        ? Icons.restaurant_outlined
                        : expense.isHousehold
                            ? Icons.home_outlined
                            : Icons.receipt_long_outlined,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSizing.md),
                Text(
                  '৳${expense.amount.toStringAsFixed(0)}',
                  style: AppTypography.headlineLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSizing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSizing.radiusFull),
                  ),
                  child: Text(
                    _categoryLabel(expense.expenseCategory),
                    style: AppTypography.titleMedium.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizing.md),

          // Details
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(AppSizing.radiusLg),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Paid by',
                  value: expense.paidByName,
                ),
                Divider(height: 1, color: context.dividerColor),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: _formatDate(expense.date),
                ),
                if (expense.description?.isNotEmpty == true) ...[
                  Divider(height: 1, color: context.dividerColor),
                  _DetailRow(
                    icon: Icons.description_outlined,
                    label: 'Description',
                    value: expense.description!,
                  ),
                ],
                Divider(height: 1, color: context.dividerColor),
                _DetailRow(
                  icon: Icons.access_time_outlined,
                  label: 'Recorded',
                  value: _formatDate(expense.createdAt),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizing.xl),

          // Actions for manager on unapproved expense
          if (!expense.isApproved && widget.canManage) ...[
            AppButton(
              label: AppStrings.approveExpenseLabel,
              onPressed: () => _confirmApprove(context, expense),
            ),
            const SizedBox(height: AppSizing.sm),
            AppButton(
              label: AppStrings.deleteExpenseLabel,
              variant: AppButtonVariant.outlined,
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.md,
        vertical: AppSizing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppSizing.iconSm + 4, color: context.textSecColor),
          const SizedBox(width: AppSizing.sm),
          Text(
            label,
            style: AppTypography.bodyMedium
                .copyWith(color: context.textSecColor),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: AppTypography.titleMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApproveResultContent extends StatelessWidget {
  const _ApproveResultContent({
    required this.result,
    required this.type,
  });

  final Map<String, dynamic> result;
  final String type;

  @override
  Widget build(BuildContext context) {
    final deducted = (result['flat_wallet_deducted'] as num?)?.toDouble();
    final newBalance = (result['flat_wallet_new_balance'] as num?)?.toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (deducted != null)
          Text(
            'Flat wallet deducted: ৳${deducted.toStringAsFixed(0)}',
            style: AppTypography.bodyMedium,
          ),
        if (newBalance != null) ...[
          const SizedBox(height: AppSizing.xs),
          Text(
            'Flat wallet balance: ৳${newBalance.toStringAsFixed(0)}',
            style: AppTypography.bodyMedium,
          ),
        ],
        if (type == 'meal') ...[
          const SizedBox(height: AppSizing.xs),
          Text(
            'Meal pool updated.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.success),
          ),
        ],
        if (type == 'household') ...[
          const SizedBox(height: AppSizing.sm),
          Text(
            'Member deductions:',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSizing.xs),
          ...(result['member_deductions'] as List? ?? []).map((d) {
            final m = d as Map<String, dynamic>;
            return Text(
              '${m['name']}: -৳${(m['deducted'] as num).toStringAsFixed(0)} → ৳${(m['new_balance'] as num).toStringAsFixed(0)}',
              style: AppTypography.bodySmall,
            );
          }),
        ],
      ],
    );
  }
}
