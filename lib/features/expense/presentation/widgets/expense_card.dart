import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/expense_entity.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
  });

  final ExpenseEntity expense;
  final VoidCallback? onTap;

  static const Color _mealColor = Color(0xFFF57C00);
  static const Color _householdColor = Color(0xFF7B1FA2);
  static const Color _fixedColor = Color(0xFF1565C0);

  Color get _categoryColor {
    switch (expense.expenseCategory) {
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

  IconData get _categoryIcon {
    switch (expense.expenseCategory) {
      case 'meal':
        return Icons.restaurant_outlined;
      case 'household':
        return Icons.home_outlined;
      case 'fixed':
        return Icons.receipt_long_outlined;
      default:
        return Icons.attach_money;
    }
  }

  String get _categoryLabel {
    switch (expense.expenseCategory) {
      case 'meal':
        return 'Meal';
      case 'household':
        return 'Household';
      case 'fixed':
        return 'Fixed';
      default:
        return expense.expenseCategory;
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

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor;
    return Material(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSizing.md),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          ),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
                child: Icon(_categoryIcon, color: color, size: AppSizing.iconMd),
              ),
              const SizedBox(width: AppSizing.md),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizing.radiusFull),
                          ),
                          child: Text(
                            _categoryLabel,
                            style: AppTypography.labelSmall.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizing.xs),
                        if (expense.isApproved)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSizing.radiusFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 10, color: AppColors.success),
                                const SizedBox(width: 2),
                                Text(
                                  'Approved',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSizing.radiusFull),
                            ),
                            child: Text(
                              'Pending',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizing.xs),
                    Text(
                      expense.description?.isNotEmpty == true
                          ? expense.description!
                          : 'No description',
                      style: AppTypography.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 12, color: context.textSecColor),
                        const SizedBox(width: 2),
                        Text(
                          expense.paidByName,
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(width: AppSizing.sm),
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: context.textSecColor),
                        const SizedBox(width: 2),
                        Text(
                          _formatDate(expense.date),
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizing.sm),
              // Amount
              Text(
                '৳${expense.amount.toStringAsFixed(0)}',
                style: AppTypography.titleLarge.copyWith(
                  color: context.textPrimColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
