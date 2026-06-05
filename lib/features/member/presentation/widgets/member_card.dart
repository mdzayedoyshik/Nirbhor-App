import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../flat/domain/entities/flat_member_entity.dart';

class MemberCard extends StatelessWidget {
  final FlatMemberEntity member;
  final bool isMe;
  final bool hasExitInProgress;
  final bool isManager;
  final bool hasCoManager;
  final void Function(String role)? onChangeRole;
  final VoidCallback? onTransferManager;
  final VoidCallback? onInitiateExit;
  final VoidCallback? onViewSettlement;

  const MemberCard({
    super.key,
    required this.member,
    required this.isMe,
    required this.hasExitInProgress,
    required this.isManager,
    required this.hasCoManager,
    this.onChangeRole,
    this.onTransferManager,
    this.onInitiateExit,
    this.onViewSettlement,
  });

  @override
  Widget build(BuildContext context) {
    final canShowActions = isManager && !isMe;
    final roleColor = _roleColor(member.role);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.md,
        vertical: AppSizing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(
          color: hasExitInProgress
              ? AppColors.warning.withValues(alpha: 0.5)
              : context.borderColor,
        ),
      ),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: member.photoUrl,
            name: member.name,
            radius: 22,
            backgroundColor: roleColor.withValues(alpha: 0.15),
            textColor: roleColor,
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
                    if (isMe) ...[
                      const SizedBox(width: AppSizing.xs),
                      _YouChip(),
                    ],
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
                if (hasExitInProgress) ...[
                  const SizedBox(height: AppSizing.xs),
                  _ExitChip(),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSizing.xs),
          if (canShowActions)
            _ActionMenu(
              member: member,
              hasExitInProgress: hasExitInProgress,
              hasCoManager: hasCoManager,
              onChangeRole: onChangeRole,
              onTransferManager: onTransferManager,
              onInitiateExit: onInitiateExit,
              onViewSettlement: onViewSettlement,
            )
          else if (!isManager && hasExitInProgress && onViewSettlement != null)
            IconButton(
              icon: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.warning,
                size: AppSizing.iconMd,
              ),
              onPressed: onViewSettlement,
              tooltip: 'View Settlement',
            ),
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

class _YouChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      ),
      child: Text(
        'You',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ExitChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.xs + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            size: 10,
            color: AppColors.warning,
          ),
          const SizedBox(width: 3),
          Text(
            'Exit in Progress',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
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
        label = 'Manager';
        color = AppColors.primary;
        break;
      case 'co-manager':
        label = 'Co-Manager';
        color = AppColors.warning;
        break;
      default:
        label = 'Member';
        color = context.textSecColor;
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

class _ActionMenu extends StatelessWidget {
  final FlatMemberEntity member;
  final bool hasExitInProgress;
  final bool hasCoManager;
  final void Function(String role)? onChangeRole;
  final VoidCallback? onTransferManager;
  final VoidCallback? onInitiateExit;
  final VoidCallback? onViewSettlement;

  const _ActionMenu({
    required this.member,
    required this.hasExitInProgress,
    required this.hasCoManager,
    this.onChangeRole,
    this.onTransferManager,
    this.onInitiateExit,
    this.onViewSettlement,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: context.textSecColor,
        size: AppSizing.iconMd,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      color: context.cardColor,
      onSelected: (value) {
        switch (value) {
          case 'make_member':
            onChangeRole?.call('member');
            break;
          case 'make_co_manager':
            onChangeRole?.call('co-manager');
            break;
          case 'transfer_manager':
            onTransferManager?.call();
            break;
          case 'initiate_exit':
            onInitiateExit?.call();
            break;
          case 'view_settlement':
            onViewSettlement?.call();
            break;
        }
      },
      itemBuilder: (menuContext) {
        final items = <PopupMenuEntry<String>>[];

        if (!hasExitInProgress) {
          // Role options (only for non-manager targets)
          if (member.role != 'manager') {
            if (member.role != 'co-manager') {
              items.add(_menuItem(
                context: menuContext,
                value: 'make_co_manager',
                icon: Icons.star_outline_rounded,
                label: 'Make Co-Manager',
                enabled: !hasCoManager,
                disabledHint: 'Demote current co-manager first',
              ));
            }
            if (member.role != 'member') {
              items.add(_menuItem(
                context: menuContext,
                value: 'make_member',
                icon: Icons.person_outline_rounded,
                label: 'Make Member',
              ));
            }
            items.add(_menuItem(
              context: menuContext,
              value: 'transfer_manager',
              icon: Icons.swap_horiz_rounded,
              label: 'Transfer Manager',
              isDestructive: true,
            ));
            if (items.isNotEmpty) items.add(const PopupMenuDivider());
            items.add(_menuItem(
              context: menuContext,
              value: 'initiate_exit',
              icon: Icons.exit_to_app_rounded,
              label: 'Initiate Exit',
              isDestructive: true,
            ));
          }
        } else {
          items.add(_menuItem(
            context: menuContext,
            value: 'view_settlement',
            icon: Icons.receipt_long_outlined,
            label: 'View Settlement',
          ));
        }

        return items;
      },
    );
  }

  PopupMenuItem<String> _menuItem({
    required BuildContext context,
    required String value,
    required IconData icon,
    required String label,
    bool isDestructive = false,
    bool enabled = true,
    String? disabledHint,
  }) {
    final color = !enabled
        ? context.textTerColor
        : isDestructive
        ? AppColors.error
        : context.textPrimColor;

    return PopupMenuItem<String>(
      value: enabled ? value : null,
      enabled: enabled,
      child: Tooltip(
        message: (!enabled && disabledHint != null) ? disabledHint : '',
        child: Row(
          children: [
            Icon(icon, size: AppSizing.iconSm + 2, color: color),
            const SizedBox(width: AppSizing.sm),
            Text(label, style: AppTypography.bodyMedium.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
