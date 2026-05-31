import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/wallet_member_summary_entity.dart';

class WalletMemberTile extends StatelessWidget {
  const WalletMemberTile({
    super.key,
    required this.member,
    this.onSendRequest,
  });

  final WalletMemberSummaryEntity member;
  final VoidCallback? onSendRequest;

  @override
  Widget build(BuildContext context) {
    final isNeg = member.isNegative;
    final balanceColor = isNeg ? AppColors.error : AppColors.success;

    return Material(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      child: InkWell(
        onLongPress: onSendRequest,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.md, vertical: AppSizing.sm + 2),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          ),
          child: Row(
            children: [
              AppAvatar(name: member.memberName, radius: 20),
              const SizedBox(width: AppSizing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.memberName, style: AppTypography.titleMedium),
                    Text(
                      _roleLabel(member.role),
                      style: AppTypography.bodySmall
                          .copyWith(color: context.textSecColor),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isNeg ? '−' : '+'}৳${member.balance.abs().toStringAsFixed(0)}',
                    style: AppTypography.titleLarge.copyWith(
                      color: balanceColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isNeg)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
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
                ],
              ),
              if (onSendRequest != null) ...[
                const SizedBox(width: AppSizing.xs),
                Icon(Icons.chevron_right,
                    size: 18, color: context.textSecColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'manager':
        return 'Manager';
      case 'co-manager':
        return 'Co-Manager';
      default:
        return 'Member';
    }
  }
}
