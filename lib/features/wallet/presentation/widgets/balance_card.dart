import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_typography.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.subtitle,
    this.trailing,
  });

  final double balance;
  final String subtitle;
  final Widget? trailing;

  bool get _isNegative => balance < 0;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        _isNegative ? AppColors.error.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.08);
    final amountColor = _isNegative ? AppColors.error : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizing.lg),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(
          color: _isNegative
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isNegative)
                Container(
                  margin: const EdgeInsets.only(right: AppSizing.xs),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius:
                        BorderRadius.circular(AppSizing.radiusFull),
                  ),
                  child: Text(
                    'Due',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                '৳${balance.abs().toStringAsFixed(0)}',
                style: AppTypography.displayLarge.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizing.xs),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textSecColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (trailing != null) ...[
            const SizedBox(height: AppSizing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
