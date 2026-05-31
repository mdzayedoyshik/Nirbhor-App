import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/flat_member_entity.dart';

class MemberTile extends StatelessWidget {
  final FlatMemberEntity member;
  final bool showContribution;

  const MemberTile({
    super.key,
    required this.member,
    this.showContribution = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.md,
        vertical: AppSizing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          AppAvatar(
            name: member.name,
            radius: 20,
            backgroundColor: _roleColor(member.role).withValues(alpha: 0.15),
            textColor: _roleColor(member.role),
          ),
          const SizedBox(width: AppSizing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        style: AppTypography.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSizing.xs),
                    _RoleBadge(role: member.role),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  style: AppTypography.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (showContribution) ...[
            const SizedBox(width: AppSizing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '৳${member.fixedContribution.toStringAsFixed(0)}',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  AppStrings.contribution,
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'manager':
        return AppColors.primary;
      case 'co-manager':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (role) {
      case 'manager':
        label = AppStrings.managerRole;
        color = AppColors.primary;
        break;
      case 'co-manager':
        label = AppStrings.coManagerRole;
        color = AppColors.warning;
        break;
      default:
        label = AppStrings.memberRole;
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.xs + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
