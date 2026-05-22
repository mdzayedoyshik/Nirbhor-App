import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../domain/entities/payment_request_entity.dart';

class PaymentRequestCard extends StatelessWidget {
  const PaymentRequestCard({
    super.key,
    required this.request,
    this.onPayNow,
    this.onCancel,
    this.showMemberName = false,
  });

  final PaymentRequestEntity request;
  final VoidCallback? onPayNow;
  final VoidCallback? onCancel;
  final bool showMemberName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(
          color: request.isPending
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
        ),
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
                    Text(
                      showMemberName
                          ? (request.requestedToName ?? '—')
                          : 'From ${request.requestedByName ?? '—'}',
                      style: AppTypography.titleMedium,
                    ),
                    if (request.note != null && request.note!.isNotEmpty)
                      Text(
                        request.note!,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                '৳${request.amount.toStringAsFixed(0)}',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizing.sm),
          if (onPayNow != null)
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Pay Now',
                onPressed: onPayNow,
                variant: AppButtonVariant.primary,
                height: AppSizing.buttonHeightSm,
              ),
            ),
          if (onCancel != null)
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Cancel Request',
                onPressed: onCancel,
                variant: AppButtonVariant.outlined,
                height: AppSizing.buttonHeightSm,
              ),
            ),
        ],
      ),
    );
  }
}
