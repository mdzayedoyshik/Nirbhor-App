import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/fixed_expense_entity.dart';

class ExpenseTile extends StatelessWidget {
  final FixedExpenseEntity expense;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.canManage = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.md,
        vertical: AppSizing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizing.radiusSm),
            ),
            child: Icon(
              _expenseIcon(expense.expenseType),
              color: AppColors.primary,
              size: AppSizing.iconMd,
            ),
          ),
          const SizedBox(width: AppSizing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _capitalize(expense.expenseType),
                  style: AppTypography.titleMedium,
                ),
              ],
            ),
          ),
          Text(
            '৳${expense.amount.toStringAsFixed(0)}',
            style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
          ),
          if (canManage) ...[
            const SizedBox(width: AppSizing.xs),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                size: AppSizing.iconMd,
                color: AppColors.textSecondary,
              ),
              onSelected: (value) {
                if (value == 'edit') onEdit?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _expenseIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('rent')) return Icons.home_outlined;
    if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi;
    if (lower.contains('electric') || lower.contains('power')) {
      return Icons.bolt_outlined;
    }
    if (lower.contains('gas')) return Icons.local_fire_department_outlined;
    if (lower.contains('water')) return Icons.water_drop_outlined;
    return Icons.receipt_outlined;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
