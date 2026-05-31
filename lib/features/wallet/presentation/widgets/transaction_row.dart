import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionRow extends StatelessWidget {
  const TransactionRow({super.key, required this.transaction});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final isDeposit = transaction.isDeposit;
    final isRefund = transaction.isRefund;

    final iconColor = isDeposit
        ? AppColors.success
        : isRefund
            ? const Color(0xFF0D9488)
            : AppColors.error;
    final icon = isDeposit
        ? Icons.arrow_downward_rounded
        : isRefund
            ? Icons.swap_horiz_rounded
            : Icons.arrow_upward_rounded;
    final amountPrefix = isDeposit || isRefund ? '+' : '−';
    final amountColor = isDeposit || isRefund ? AppColors.success : AppColors.error;

    String categoryLabel = '';
    if (transaction.category != null) {
      switch (transaction.category) {
        case 'fixed':
          categoryLabel = 'Fixed';
        case 'meal':
          categoryLabel = 'Meal';
        case 'household':
          categoryLabel = 'Household';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizing.radiusFull),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSizing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: AppTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    if (categoryLabel.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusFull),
                        ),
                        child: Text(
                          categoryLabel,
                          style: AppTypography.labelSmall.copyWith(
                            color: context.textSecColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizing.xs),
                    ],
                    Text(
                      _formatDate(transaction.createdAt),
                      style: AppTypography.bodySmall.copyWith(
                        color: context.textSecColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '$amountPrefix৳${transaction.amount.toStringAsFixed(0)}',
            style: AppTypography.titleLarge.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return iso;
    }
  }
}
