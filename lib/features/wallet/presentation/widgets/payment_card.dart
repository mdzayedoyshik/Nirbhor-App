import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../domain/entities/payment_entity.dart';

class PaymentCard extends StatelessWidget {
  const PaymentCard({
    super.key,
    required this.payment,
    this.onVerify,
    this.onReject,
  });

  final PaymentEntity payment;
  final VoidCallback? onVerify;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payment.fromMemberName ?? '—',
                        style: AppTypography.titleLarge),
                    Text(
                      payment.paymentMethod.toUpperCase(),
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '৳${payment.amount.toStringAsFixed(0)}',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _StatusChip(status: payment.status),
                ],
              ),
            ],
          ),
          if (payment.note != null && payment.note!.isNotEmpty) ...[
            const SizedBox(height: AppSizing.xs),
            Text(
              payment.note!,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSizing.xs),
          Text(
            _formatDate(payment.createdAt),
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          if (onVerify != null || onReject != null) ...[
            const SizedBox(height: AppSizing.sm),
            Row(
              children: [
                if (onVerify != null)
                  Expanded(
                    child: AppButton(
                      label: 'Verify',
                      onPressed: onVerify,
                      variant: AppButtonVariant.primary,
                      height: AppSizing.buttonHeightSm,
                    ),
                  ),
                if (onVerify != null && onReject != null)
                  const SizedBox(width: AppSizing.sm),
                if (onReject != null)
                  Expanded(
                    child: AppButton(
                      label: 'Reject',
                      onPressed: onReject,
                      variant: AppButtonVariant.outlined,
                      height: AppSizing.buttonHeightSm,
                    ),
                  ),
              ],
            ),
          ],
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
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'verified':
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
      case 'rejected':
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
      case 'cancelled':
        bg = AppColors.textSecondary.withValues(alpha: 0.12);
        fg = AppColors.textSecondary;
      default: // pending
        bg = AppColors.warning.withValues(alpha: 0.12);
        fg = AppColors.warning;
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSizing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: AppTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
