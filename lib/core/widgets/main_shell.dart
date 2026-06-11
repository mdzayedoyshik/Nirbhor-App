import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizing.dart';
import '../constants/app_typography.dart';
import '../router/app_router.dart';
import 'review_prompt.dart';
import '../../features/notification/presentation/bloc/notification_bloc.dart';
import '../../features/notification/presentation/bloc/notification_state.dart';

/// Bottom-nav shell for authenticated users.
///
/// Wrap the current page with [MainShell] and pass the [selectedIndex] that
/// matches the active tab (0 = Home, 1 = Meals, 2 = Wallet, 3 = Expenses).
/// Index 4 (More) opens a modal bottom sheet instead of navigating.
///
/// Because the router uses flat GoRoutes (not ShellRoute), [MainShell] is used
/// as a standalone wrapper inside each top-level destination page rather than
/// as a persistent shell.
class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    // Extra context objects needed for navigation
    this.flatId,
    this.flatName,
    this.walletPageArgs,
  });

  final Widget child;
  final int selectedIndex;

  /// Pass the current flat's id so the shell can navigate wallet/meals.
  final String? flatId;
  final String? flatName;

  /// Pre-built wallet args object so the Wallet tab can navigate.
  final Object? walletPageArgs;

  static const _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.restaurant_outlined,
      activeIcon: Icons.restaurant_rounded,
      label: 'Meals',
    ),
    _NavItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      label: 'Wallet',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Expenses',
    ),
    _NavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'More',
    ),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == selectedIndex) return;
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        // Meals requires MealPageArgs; navigate home if args unavailable
        context.go(AppRoutes.home);
      case 2:
        if (walletPageArgs != null) {
          context.push(AppRoutes.walletHome, extra: walletPageArgs);
        } else {
          context.go(AppRoutes.home);
        }
      case 3:
        context.go(AppRoutes.home);
      case 4:
        _showMoreSheet(context);
    }
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizing.r24),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizing.pagePadding,
          AppSizing.sp16,
          AppSizing.pagePadding,
          AppSizing.sp32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: AppSizing.bottomSheetHandleWidth,
              height: AppSizing.bottomSheetHandleHeight,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(AppSizing.rFull),
              ),
            ),
            const SizedBox(height: AppSizing.sp16),
            Text('More', style: AppTypography.h3),
            const SizedBox(height: AppSizing.sp16),
            Divider(height: 1, color: context.dividerColor),
            const SizedBox(height: AppSizing.sp16),
            _MoreItem(
              icon: Icons.bar_chart_rounded,
              label: 'Monthly Summary',
              onTap: () => Navigator.pop(context),
            ),
            _MoreItem(
              icon: Icons.task_alt_rounded,
              label: 'Tasks',
              onTap: () => Navigator.pop(context),
            ),
            _MoreItem(
              icon: Icons.report_problem_outlined,
              label: 'Complaints',
              onTap: () => Navigator.pop(context),
            ),
            _MoreItem(
              icon: Icons.history_edu_rounded,
              label: 'Audit Log',
              onTap: () => Navigator.pop(context),
            ),
            _MoreItem(
              icon: Icons.settings_outlined,
              label: 'Flat Settings',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ReviewPromptGate(child: child),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.bottomNavBg,
          border: Border(
            top: BorderSide(
              color: context.borderColor,
              width: AppSizing.borderWidth,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppSizing.bottomNavHeight,
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isActive = i == selectedIndex;

                // Notification badge on Home tab
                if (i == 0) {
                  return BlocBuilder<NotificationBloc, NotificationState>(
                    builder: (ctx, state) {
                      int count = 0;
                      if (state is NotificationUnreadCountLoaded) {
                        count = state.unreadCount;
                      } else if (state is NotificationListLoaded) {
                        count = state.unreadCount;
                      } else if (state is NotificationError) {
                        count = state.unreadCount;
                      }
                      return _NavTile(
                        item: item,
                        isActive: isActive,
                        badge: count,
                        onTap: () => _onTap(context, i),
                      );
                    },
                  );
                }

                return _NavTile(
                  item: item,
                  isActive: isActive,
                  onTap: () => _onTap(context, i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Internal nav tile ─────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
    this.badge = 0,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final activeColor = AppColors.brand;
    final inactiveColor =
        isDark ? AppColors.darkTextTertiary : AppColors.textTertiary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Pill background for active state
                if (isActive)
                  Container(
                    width: 40,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizing.rFull),
                    ),
                  ),
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: AppSizing.iconMd,
                  color: isActive ? activeColor : inactiveColor,
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppSizing.rFull),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: AppTypography.labelS.copyWith(
                color: isActive ? activeColor : inactiveColor,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── More sheet item ───────────────────────────────────────────────────────────

class _MoreItem extends StatelessWidget {
  const _MoreItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppSizing.r12),
        ),
        child: Icon(icon, size: AppSizing.iconMd, color: AppColors.brand),
      ),
      title: Text(label, style: AppTypography.labelL),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
