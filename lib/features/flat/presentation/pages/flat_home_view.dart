import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/quick_action_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../audit_log/presentation/args/audit_log_page_args.dart';
import '../../../complaint/presentation/args/complaint_page_args.dart';
import '../../../expense/presentation/bloc/expense_bloc.dart';
import '../../../expense/presentation/pages/expense_list_page.dart';
import '../../../meal/presentation/args/meal_page_args.dart';
import '../../../meal/presentation/bloc/meal_bloc.dart';
import '../../../meal/presentation/bloc/meal_pool_bloc.dart';
import '../../../meal/presentation/bloc/meal_prefs_bloc.dart';
import '../../../meal/presentation/pages/meal_page.dart';
import '../../../notification/presentation/args/notification_page_args.dart';
import '../../../notification/presentation/bloc/notification_bloc.dart';
import '../../../notification/presentation/bloc/notification_state.dart';
import '../../../summary/presentation/args/summary_page_args.dart';
import '../../../task/presentation/args/task_page_args.dart';
import '../../../wallet/presentation/args/wallet_page_args.dart';
import '../../../wallet/presentation/bloc/wallet/wallet_bloc.dart';
import '../../../wallet/presentation/pages/wallet_home_page.dart';
import '../../domain/entities/flat_entity.dart';
import '../../domain/entities/flat_member_entity.dart';
import '../bloc/flat_bloc.dart';
import '../bloc/join_requests_bloc.dart';
import '../widgets/member_tile.dart';

// ── Nav items ─────────────────────────────────────────────────────────────────

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

const _navItems = [
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
];

// ── Shell widget ──────────────────────────────────────────────────────────────

class FlatHomeView extends StatefulWidget {
  final FlatEntity flat;
  const FlatHomeView({super.key, required this.flat});

  @override
  State<FlatHomeView> createState() => _FlatHomeViewState();
}

class _FlatHomeViewState extends State<FlatHomeView> {
  int _tab = 0;
  // true = tab has been loaded at least once; start only home as loaded
  final List<bool> _loaded = [true, false, false, false];

  FlatMemberEntity? _myMember() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return null;
    return widget.flat.memberByUserId(authState.user.id);
  }

  @override
  void initState() {
    super.initState();
    // Load wallet summary eagerly so the home balance card shows immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<WalletBloc>()
            .add(WalletSummaryRequested(widget.flat.id));
      }
    });
  }

  void _switchTab(int i) {
    if (i == _tab) return;
    setState(() {
      if (i < _loaded.length) _loaded[i] = true;
      _tab = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = _myMember();
    final canManage = me?.canManage ?? false;

    return BlocListener<FlatBloc, FlatState>(
      listener: (context, state) {
        if (state is FlatError) AppSnackbar.error(context, state.message);
      },
      child: Scaffold(
        backgroundColor: context.bgColor,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: IndexedStack(
            index: _tab,
            children: [
              // Tab 0 — Home dashboard
              _HomeDashboard(
                flat: widget.flat,
                me: me,
                canManage: canManage,
                onTabSelect: _switchTab,
              ),
              // Tab 1 — Meals (lazy)
              _loaded[1] && me != null
                  ? MultiBlocProvider(
                      providers: [
                        BlocProvider(create: (_) => sl<MealBloc>()),
                        BlocProvider(create: (_) => sl<MealPoolBloc>()),
                        BlocProvider(create: (_) => sl<MealPrefsBloc>()),
                      ],
                      child: MealPage(
                        args: MealPageArgs(
                          flatId: widget.flat.id,
                          canManage: canManage,
                          myMemberId: me.flatMemberId,
                          members: widget.flat.activeMembers,
                        ),
                      ),
                    )
                  : const SizedBox.expand(),
              // Tab 2 — Wallet (lazy) — WalletBloc is the global singleton
              // already provided at the home route level, so no extra provider needed.
              _loaded[2]
                  ? WalletHomePage(
                      args: WalletPageArgs(
                        flatId: widget.flat.id,
                        canManage: canManage,
                      ),
                    )
                  : const SizedBox.expand(),
              // Tab 3 — Expenses (lazy)
              _loaded[3]
                  ? BlocProvider(
                      create: (_) => sl<ExpenseBloc>(),
                      child: ExpenseListPage(
                        flatId: widget.flat.id,
                        canManage: canManage,
                        memberCount: widget.flat.activeMembers.length,
                      ),
                    )
                  : const SizedBox.expand(),
            ],
          ),
        ),
        bottomNavigationBar: _BottomNavBar(
          selectedIndex: _tab,
          onTap: _switchTab,
        ),
      ),
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bottomNavBg,
        border: Border(
          top: BorderSide(
            color: AppColors.surface200,
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

              // Notification badge on Home tab (index 0)
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
                      onTap: () => onTap(i),
                    );
                  },
                );
              }

              return _NavTile(
                item: item,
                isActive: isActive,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
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
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius:
                            BorderRadius.circular(AppSizing.rFull),
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

// ── Home Dashboard (Tab 0) ────────────────────────────────────────────────────

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({
    required this.flat,
    required this.me,
    required this.canManage,
    required this.onTabSelect,
  });

  final FlatEntity flat;
  final FlatMemberEntity? me;
  final bool canManage;
  final ValueChanged<int> onTabSelect;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _greetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: () async {
          context.read<FlatBloc>().add(FlatRefreshRequested(flat.id));
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. HEADER ────────────────────────────────────────────────
              _HomeHeader(
                flat: flat,
                me: me,
                canManage: canManage,
                greeting: _greeting(),
                greetingEmoji: _greetingEmoji(),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: -0.1, end: 0, duration: 300.ms),

              const SizedBox(height: AppSizing.sp16),

              // ── 2. STATS ROW ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizing.pagePadding,
                ),
                child: _StatsRow(
                  flat: flat,
                  me: me,
                  canManage: canManage,
                  onTabSelect: onTabSelect,
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 80.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms),

              const SizedBox(height: AppSizing.sp24),

              // ── 3. QUICK ACTIONS ─────────────────────────────────────────
              _QuickActionsRow(
                flat: flat,
                me: me,
                canManage: canManage,
                onTabSelect: onTabSelect,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 140.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms),

              const SizedBox(height: AppSizing.sp24),

              // ── 4. PENDING ACTIONS (manager only) ────────────────────────
              if (canManage) ...[
                _PendingActionsSection(flat: flat)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 180.ms),
                const SizedBox(height: AppSizing.sp24),
              ],

              // ── 5. MEMBERS GLIMPSE ───────────────────────────────────────
              SectionHeader(
                title: AppStrings.membersSection,
                actionLabel: AppStrings.viewAll,
                onAction: () => context
                    .push(AppRoutes.flatMembers, extra: flat)
                    .then((_) {
                  if (context.mounted) {
                    context
                        .read<FlatBloc>()
                        .add(FlatRefreshRequested(flat.id));
                  }
                }),
              )
                  .animate()
                  .fadeIn(duration: 350.ms, delay: 220.ms),
              const SizedBox(height: AppSizing.sp12),
              _MembersGlimpse(flat: flat)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 240.ms),

              const SizedBox(height: AppSizing.sp48),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 1. Header ─────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.flat,
    required this.me,
    required this.canManage,
    required this.greeting,
    required this.greetingEmoji,
  });

  final FlatEntity flat;
  final FlatMemberEntity? me;
  final bool canManage;
  final String greeting;
  final String greetingEmoji;

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizing.radiusLg)),
      ),
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<ThemeCubit>(),
        child: _SettingsSheet(flat: flat, canManage: canManage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizing.pagePadding,
        AppSizing.sp16,
        AppSizing.pagePadding,
        AppSizing.sp8,
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => context.push(AppRoutes.profile),
            child: AppAvatar(
              imageUrl: user?.avatarUrl,
              name: user?.name ?? flat.name,
              radius: AppSizing.avatar40 / 2,
              backgroundColor: AppColors.brand.withValues(alpha: 0.15),
              textColor: AppColors.brand,
            ),
          ),

          const SizedBox(width: AppSizing.sp12),

          // Greeting text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, ${user?.name.split(' ').first ?? 'there'} $greetingEmoji',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  flat.name,
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.textSecondary,
            onPressed: () => _showSettingsSheet(context),
          ),

          // Notification bell
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, notifState) {
              int count = 0;
              if (notifState is NotificationUnreadCountLoaded) {
                count = notifState.unreadCount;
              } else if (notifState is NotificationListLoaded) {
                count = notifState.unreadCount;
              } else if (notifState is NotificationError) {
                count = notifState.unreadCount;
              }
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      count > 0
                          ? Icons.notifications_rounded
                          : Icons.notifications_outlined,
                      color: count > 0
                          ? AppColors.brand
                          : AppColors.textSecondary,
                    ),
                    onPressed: () => context.push(
                      AppRoutes.notifications,
                      extra: NotificationPageArgs(
                        flatId: flat.id,
                        canManage: me?.canManage ?? false,
                        myMemberId: me?.flatMemberId ?? '',
                      ),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── 2. Stats Row ──────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.flat,
    required this.me,
    required this.canManage,
    required this.onTabSelect,
  });

  final FlatEntity flat;
  final FlatMemberEntity? me;
  final bool canManage;
  final ValueChanged<int> onTabSelect;

  String _currentMealLabel() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Breakfast time';
    if (h < 15) return 'Lunch time';
    if (h < 22) return 'Dinner time';
    return 'Meals';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, walletState) {
        final summary = switch (walletState) {
          WalletSummaryLoaded(summary: final s) => s,
          WalletActionLoading(summary: final s) => s,
          WalletPaymentSubmitSuccess(summary: final s) => s,
          WalletError(summary: final s) when s != null => s,
          _ => null,
        };
        final flatWallet = switch (walletState) {
          WalletSummaryLoaded(flatWallet: final fw) => fw,
          WalletActionLoading(flatWallet: final fw) => fw,
          WalletPaymentSubmitSuccess(flatWallet: final fw) => fw,
          _ => null,
        };

        final balanceText = summary == null
            ? '--'
            : '${summary.isNegative ? '−' : ''}৳${summary.walletBalance.abs().toStringAsFixed(0)}';
        final poolText = flatWallet == null
            ? '--'
            : '${flatWallet.isNegative ? '−' : ''}৳${flatWallet.balance.abs().toStringAsFixed(0)}';

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTabSelect(2),
                    child: _StatCard(
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: AppColors.brand,
                      label: 'Balance',
                      value: balanceText,
                      subtitle: summary?.isNegative == true ? 'owed' : 'available',
                    ),
                  ),
                ),
                const SizedBox(width: AppSizing.sp12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTabSelect(2),
                    child: _StatCard(
                      icon: Icons.account_balance_rounded,
                      iconColor: AppColors.success,
                      label: 'Pool',
                      value: poolText,
                      subtitle: flatWallet?.isNegative == true ? 'deficit' : 'available',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizing.sp12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context
                        .push(AppRoutes.flatMembers, extra: flat)
                        .then((_) {
                      if (context.mounted) {
                        context
                            .read<FlatBloc>()
                            .add(FlatRefreshRequested(flat.id));
                      }
                    }),
                    child: _StatCard(
                      icon: Icons.group_rounded,
                      iconColor: AppColors.info,
                      label: 'Members',
                      value: '${flat.activeMembers.length}',
                      subtitle: 'active',
                    ),
                  ),
                ),
                const SizedBox(width: AppSizing.sp12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTabSelect(1),
                    child: _StatCard(
                      icon: Icons.restaurant_rounded,
                      iconColor: const Color(0xFF10B981),
                      label: 'Meals',
                      value: _currentMealLabel(),
                      subtitle: 'tap to log',
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.sp16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.r16),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizing.r12),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: AppSizing.sp8),
          Text(
            value,
            style: AppTypography.amountL.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '$label · $subtitle',
            style: AppTypography.labelS.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3. Quick Actions Row ──────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.flat,
    required this.me,
    required this.canManage,
    required this.onTabSelect,
  });

  final FlatEntity flat;
  final FlatMemberEntity? me;
  final bool canManage;
  final ValueChanged<int> onTabSelect;

  void _showQrSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusLg),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSizing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSizing.md),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              ),
            ),
            Text(
              'Invite to ${flat.name}',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: AppSizing.xs),
            Text(
              'Share this QR code or join code with others',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizing.lg),
            QrImageView(
              data: flat.joinCode,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: AppColors.white,
              padding: const EdgeInsets.all(AppSizing.sm),
            ),
            const SizedBox(height: AppSizing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizing.md,
                vertical: AppSizing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                flat.joinCode,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSizing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: flat.joinCode));
                  AppSnackbar.success(
                    context,
                    'Join code copied: ${flat.joinCode}',
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSizing.sm),
                ),
              ),
            ),
            const SizedBox(height: AppSizing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Quick action buttons
    final commonActions = <Widget>[
      QuickActionButton(
        icon: Icons.task_alt_rounded,
        label: 'Tasks',
        onTap: () {
          if (me == null) return;
          context.push(
            AppRoutes.tasks,
            extra: TaskPageArgs(
              flatId: flat.id,
              canManage: canManage,
              myMemberId: me!.flatMemberId,
              members: flat.activeMembers,
            ),
          );
        },
      ),
      QuickActionButton(
        icon: Icons.report_problem_outlined,
        label: 'Complaints',
        onTap: () {
          if (me == null) return;
          context.push(
            AppRoutes.complaints,
            extra: ComplaintPageArgs(
              flatId: flat.id,
              canManage: canManage,
              myMemberId: me!.flatMemberId,
            ),
          );
        },
      ),
      QuickActionButton(
        icon: Icons.bar_chart_rounded,
        label: 'Summary',
        onTap: () {
          if (me == null) return;
          context.push(
            AppRoutes.summary,
            extra: SummaryPageArgs(
              flatId: flat.id,
              isManager: canManage,
              myMemberId: me!.flatMemberId,
            ),
          );
        },
      ),
      QuickActionButton(
        icon: Icons.monetization_on_outlined,
        label: 'Fixed Exp.',
        onTap: () => context.push(
          AppRoutes.flatExpenses,
          extra: {'flatId': flat.id, 'canManage': canManage},
        ),
      ),
      QuickActionButton(
        icon: Icons.qr_code_rounded,
        label: 'Invite',
        onTap: () => _showQrSheet(context),
      ),
    ];

    // Buttons 9 & 10 differ by role
    final roleActions = canManage
        ? <Widget>[
            QuickActionButton(
              icon: Icons.history_edu_rounded,
              label: 'Audit',
              onTap: () => context.push(
                AppRoutes.auditLog,
                extra: AuditLogPageArgs(flatId: flat.id),
              ),
            ),
            BlocBuilder<JoinRequestsBloc, JoinRequestsState>(
              builder: (context, reqState) {
                int pendingCount = 0;
                if (reqState is JoinRequestsLoaded) {
                  pendingCount =
                      reqState.requests.where((r) => r.isPending).length;
                }
                return QuickActionButton(
                  icon: Icons.group_add_outlined,
                  label: 'Requests',
                  badge: pendingCount,
                  onTap: () => context
                      .push(AppRoutes.flatRequests, extra: flat.id)
                      .then((_) {
                    // JoinRequestsBloc re-fetches internally after approve/decline;
                    // only refresh the flat to sync member count etc.
                    if (context.mounted) {
                      context
                          .read<FlatBloc>()
                          .add(FlatRefreshRequested(flat.id));
                    }
                  }),
                );
              },
            ),
          ]
        : <Widget>[
            QuickActionButton(
              icon: Icons.group_outlined,
              label: 'Members',
              onTap: () => context
                  .push(AppRoutes.flatMembers, extra: flat)
                  .then((_) {
                if (context.mounted) {
                  context
                      .read<FlatBloc>()
                      .add(FlatRefreshRequested(flat.id));
                }
              }),
            ),
            QuickActionButton(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () => context.push(
                AppRoutes.notifications,
                extra: NotificationPageArgs(
                  flatId: flat.id,
                  canManage: false,
                  myMemberId: me?.flatMemberId ?? '',
                ),
              ),
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: AppSizing.sp12),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
          child: GridView.count(
            crossAxisCount: 5,
            mainAxisSpacing: AppSizing.sp8,
            crossAxisSpacing: AppSizing.sp8,
            childAspectRatio: 0.85,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [...commonActions, ...roleActions],
          ),
        ),
      ],
    );
  }
}

// ── 4. Pending Actions (manager) ──────────────────────────────────────────────

class _PendingActionsSection extends StatelessWidget {
  const _PendingActionsSection({required this.flat});

  final FlatEntity flat;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JoinRequestsBloc, JoinRequestsState>(
      builder: (context, reqState) {
        final pendingCount = reqState is JoinRequestsLoaded
            ? reqState.requests.where((r) => r.isPending).length
            : 0;

        if (pendingCount == 0) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              eyebrow: 'action needed',
              title: 'Pending',
            ),
            const SizedBox(height: AppSizing.sp12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizing.pagePadding,
              ),
              child: _PendingCard(
                icon: Icons.group_add_outlined,
                accentColor: AppColors.warning,
                title:
                    '$pendingCount join request${pendingCount > 1 ? 's' : ''}',
                subtitle: 'Awaiting your approval',
                actionLabel: 'Review',
                onAction: () => context
                    .push(AppRoutes.flatRequests, extra: flat.id)
                    .then((_) {
                  // JoinRequestsBloc re-fetches internally after approve/decline;
                  // only refresh the flat to sync member count etc.
                  if (context.mounted) {
                    context
                        .read<FlatBloc>()
                        .add(FlatRefreshRequested(flat.id));
                  }
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizing.r16),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
        boxShadow: AppColors.shadowSm,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizing.r12),
          ),
          child: Icon(icon, size: AppSizing.iconMd, color: accentColor),
        ),
        title: Text(title, style: AppTypography.labelL),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodyS.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: accentColor,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSizing.sp12),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: AppTypography.labelM.copyWith(color: accentColor),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizing.sp16,
          vertical: AppSizing.sp8,
        ),
      ),
    );
  }
}

// ── 5. Members Glimpse ────────────────────────────────────────────────────────

class _MembersGlimpse extends StatelessWidget {
  const _MembersGlimpse({required this.flat});

  final FlatEntity flat;

  @override
  Widget build(BuildContext context) {
    final members = flat.activeMembers.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
      child: Column(
        children: members
            .map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizing.sp8),
                child: MemberTile(member: m),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Settings Sheet ────────────────────────────────────────────────────────────

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.flat, required this.canManage});

  final FlatEntity flat;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizing.pagePadding,
        AppSizing.md,
        AppSizing.pagePadding,
        MediaQuery.of(context).viewInsets.bottom + AppSizing.pagePadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSizing.md),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              ),
            ),
          ),
          Text('Settings', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSizing.md),

          // Flat Settings (manager only)
          if (canManage) ...[
            _SettingsTile(
              icon: Icons.home_work_outlined,
              label: 'Flat Settings',
              subtitle: 'Name, photo, meal config',
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.flatSettings, extra: flat);
              },
            ),
            const SizedBox(height: AppSizing.sm),
          ],

          // Theme
          Text(
            'Theme',
            style: AppTypography.labelM.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizing.xs),
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return Row(
                children: [
                  _ThemeOption(
                    icon: Icons.light_mode_rounded,
                    label: 'Light',
                    selected: state.mode == ThemeMode.light,
                    onTap: () =>
                        context.read<ThemeCubit>().setTheme(ThemeMode.light),
                  ),
                  const SizedBox(width: AppSizing.sm),
                  _ThemeOption(
                    icon: Icons.dark_mode_rounded,
                    label: 'Dark',
                    selected: state.mode == ThemeMode.dark,
                    onTap: () =>
                        context.read<ThemeCubit>().setTheme(ThemeMode.dark),
                  ),
                  const SizedBox(width: AppSizing.sm),
                  _ThemeOption(
                    icon: Icons.brightness_auto_rounded,
                    label: 'System',
                    selected: state.mode == ThemeMode.system,
                    onTap: () =>
                        context.read<ThemeCubit>().setTheme(ThemeMode.system),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSizing.sm),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.brand.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        ),
        child: Icon(icon, size: 20, color: AppColors.brand),
      ),
      title: Text(label, style: AppTypography.titleMedium),
      subtitle: Text(subtitle,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSizing.sm),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brand.withValues(alpha: 0.1)
                : context.cardColor,
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            border: Border.all(
              color: selected
                  ? AppColors.brand
                  : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? AppColors.brand : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.labelS.copyWith(
                  color: selected ? AppColors.brand : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
