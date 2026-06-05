import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/meal_pool_entity.dart';

class PoolBreakdownRow extends StatelessWidget {
  const PoolBreakdownRow({
    super.key,
    required this.member,
    required this.isMe,
  });

  final MealPoolMemberEntity member;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.md, vertical: AppSizing.sm + 2),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withValues(alpha: 0.04)
            : context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.25)
              : context.borderColor,
        ),
      ),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: member.photoUrl,
            name: member.memberName,
            radius: 18,
            backgroundColor: isMe
                ? AppColors.primary.withValues(alpha: 0.15)
                : context.surfaceColor,
            textColor: isMe ? AppColors.primary : context.textSecColor,
          ),
          const SizedBox(width: AppSizing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.memberName,
                        style: AppTypography.titleMedium.copyWith(
                          color: isMe
                              ? AppColors.primary
                              : context.textPrimColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: AppSizing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusFull),
                        ),
                        child: Text(
                          'You',
                          style: AppTypography.labelSmall.copyWith(
                              fontSize: 10, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${member.totalPoints.toStringAsFixed(1)} pts',
                  style: AppTypography.bodySmall
                      .copyWith(color: context.textSecColor),
                ),
              ],
            ),
          ),
          Text(
            '৳${member.estimatedMealCost.toStringAsFixed(0)}',
            style: AppTypography.titleMedium.copyWith(
              color: isMe ? AppColors.primary : context.textPrimColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
