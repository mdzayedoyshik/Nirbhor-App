import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/quick_action_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../audit_log/presentation/args/audit_log_page_args.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../complaint/presentation/args/complaint_page_args.dart';
import '../../../complaint/presentation/bloc/complaint_bloc.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../expense/presentation/bloc/expense_bloc.dart';
import '../../../expense/presentation/pages/expense_list_page.dart';
import '../../../task/presentation/bloc/task_bloc.dart';
import '../../../wallet/presentation/bloc/payments/payments_bloc.dart';
import '../../../meal/presentation/args/meal_page_args.dart';
import '../../../meal/presentation/bloc/meal_bloc.dart';
import '../../../meal/presentation/bloc/meal_pool_bloc.dart';
import '../../../meal/presentation/bloc/meal_prefs_bloc.dart';
import '../../../meal/presentation/pages/meal_page.dart';
import '../../../notification/presentation/args/notification_page_args.dart';
import '../../../notification/presentation/bloc/notification_bloc.dart';
import '../../../notification/presentation/bloc/notification_state.dart';
import '../../../summary/presentation/args/summary_page_args.dart';
import '../../../summary/presentation/bloc/month_close_checklist_bloc.dart';
import '../../../task/presentation/args/task_page_args.dart';
import '../../../wallet/presentation/args/wallet_page_args.dart';
import '../../../wallet/presentation/bloc/wallet/wallet_bloc.dart';
import '../../../wallet/presentation/pages/wallet_home_page.dart';
import '../../../onboarding/presentation/widgets/getting_started_card.dart';
import '../../domain/entities/flat_entity.dart';
import '../../domain/entities/flat_member_entity.dart';
import '../bloc/flat_bloc.dart';
import '../bloc/join_requests_bloc.dart';
import '../pages/flat_settings_page.dart';
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

const _baseNavItems = [
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

const _settingsNavItem = _NavItem(
  icon: Icons.settings_outlined,
  activeIcon: Icons.settings_rounded,
  label: 'Settings',
);

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
  final List<bool> _loaded = [true, false, false, false, false];
  // Guard against showing the exit dialog twice if back is pressed rapidly
  bool _isExiting = false;

  StreamSubscription<ForegroundPushEvent>? _pushSub;

  FlatMemberEntity? _myMember() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return null;
    return widget.flat.memberByUserId(authState.user.id);
  }

  /// Reloads all home-level pending-action blocs.
  /// Called on initial mount, pull-to-refresh, after navigating back from
  /// screens that may change pending state, and on relevant foreground pushes.
  void _reloadPendingActions() {
    final me = _myMember();
    if (me == null) return;
    final flatId    = widget.flat.id;
    final canManage = me.canManage;
    final myMemberId = me.flatMemberId;

    // Tasks assigned to me — pending status only for accuracy
    context.read<TaskBloc>().add(
          TasksLoadRequested(flatId, assignedTo: myMemberId, status: 'pending'),
        );

    // Complaints — managers see all open, members see their own open
    context.read<ComplaintBloc>().add(
          ComplaintsLoadRequested(
            flatId,
            status: 'open',
            raisedBy: canManage ? null : myMemberId,
          ),
        );

    if (canManage) {
      // Payments submitted by members, awaiting manager verification
      context.read<PaymentsBloc>().add(
            PaymentsLoadRequested(flatId, status: 'pending'),
          );
      // Expenses submitted by members that have not been approved yet
      context.read<ExpenseBloc>().add(
            ExpensesLoadRequested(flatId, isApproved: false),
          );
      // Month-close checklist (oldest unclosed previous month + blockers)
      context.read<MonthCloseChecklistBloc>().add(
            MonthCloseChecklistStatusRequested(flatId),
          );
      // Join requests — powers both the quick-action badge and the pending card
      context.read<JoinRequestsBloc>().add(
            JoinRequestsLoadRequested(flatId),
          );
    } else {
      // Member: reload wallet summary so the pending payment-request card stays
      // accurate when a manager sends a new payment request.
      context.read<WalletBloc>().add(WalletSummaryRequested(flatId));
    }
  }

  @override
  void initState() {
    super.initState();
    // Eagerly load all home-screen data after the first frame so the stat
    // cards populate immediately regardless of FlatBloc listener timing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WalletBloc>().add(WalletSummaryRequested(widget.flat.id));
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      context.read<MealBloc>().add(MealDailyLoadRequested(
            flatId: widget.flat.id,
            date: todayStr,
          ));
      context.read<MealPoolBloc>().add(MealPoolLoadRequested(
            flatId: widget.flat.id,
            month: now.month,
            year: now.year,
          ));
      // Load pending-action data for the home dashboard
      _reloadPendingActions();
    });

    // Reload pending-action blocs whenever a relevant foreground push
    // arrives while the Home tab is visible, so the section stays live
    // without requiring a manual pull-to-refresh.
    _pushSub = PushNotificationService.instance.foregroundStream.listen((event) {
      if (!mounted) return;
      if (event.flatId != widget.flat.id) return; // different flat — ignore
      if (_tab != 0) return;                       // Home tab not visible — skip
      final t = event.type;

      // Reload pending-actions blocs for all action-relevant push types.
      if (t.contains('task')         ||  // task_assigned, task_status_updated
          t.contains('complaint')    ||  // complaint_raised, complaint_status_updated
          t.contains('expense')      ||  // expense_submitted, expense_approved
          t.contains('payment')      ||  // payment_submitted/verified/rejected/request_received
          t.contains('contribution') ||  // fixed_contribution_deducted
          t.contains('join_request') ||  // join_request_received
          t.contains('member')       ||  // member_joined, member_exit_initiated
          t.contains('month_closed') ||  // month_closed (co-manager sees checklist clear)
          t.contains('monthly')) {       // monthly_summary (any summary-related type)
        _reloadPendingActions();
      }

      // Member-count changes also need the flat entity itself refreshed
      // so the Members stat card and member list stay accurate.
      if (t.contains('member')) {
        context.read<FlatBloc>().add(FlatRefreshRequested(widget.flat.id));
      }
    });
  }

  @override
  void dispose() {
    _pushSub?.cancel();
    super.dispose();
  }

  void _switchTab(int i) {
    if (i == _tab) return;
    final returningToHome = i == 0 && _tab != 0;
    setState(() {
      if (i < _loaded.length) _loaded[i] = true;
      _tab = i;
    });
    // Reload pending-action blocs whenever the user returns to the Home tab
    // so any changes made in other tabs are reflected immediately.
    if (returningToHome) _reloadPendingActions();
  }

  @override
  Widget build(BuildContext context) {
    final me = _myMember();
    final canManage = me?.canManage ?? false;
    final navItems = canManage
        ? [..._baseNavItems, _settingsNavItem]
        : _baseNavItems;
    final effectiveTab = canManage ? _tab : (_tab < navItems.length ? _tab : 0);

    return PopScope(
      // Never let the system pop automatically — we handle it ourselves.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return; // already handled elsewhere
        // If not on the Home tab, go back to Home instead of exiting.
        if (_tab != 0) {
          _switchTab(0);
          return;
        }
        // On Home tab — show exit confirmation.
        if (_isExiting) return; // guard against rapid double-press
        _isExiting = true;
        final shouldExit = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text('Exit App', style: AppTypography.titleLarge),
            content: Text(
              'Are you sure you want to exit?',
              style: AppTypography.bodyMedium
                  .copyWith(color: ctx.textSecColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancel',
                  style: AppTypography.labelM
                      .copyWith(color: ctx.textSecColor),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Exit',
                  style: AppTypography.labelM
                      .copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
        _isExiting = false;
        if (shouldExit == true && mounted) {
          SystemNavigator.pop();
        }
      },
      child: BlocListener<FlatBloc, FlatState>(
        listener: (context, state) {
          if (state is FlatError) AppSnackbar.error(context, state.message);
        },
        child: Scaffold(
          backgroundColor: context.bgColor,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: IndexedStack(
            index: effectiveTab,
            children: [
              // Tab 0 — Home dashboard
              _HomeDashboard(
                flat: widget.flat,
                me: me,
                canManage: canManage,
                onTabSelect: _switchTab,
                onReloadPending: _reloadPendingActions,
              ),
              // Tab 1 — Meals (lazy)
              // Share the home-level MealBloc/MealPoolBloc instances (.value)
              // so the stat card and Meals tab stay in sync.
              // MealPrefsBloc is only needed in the tab, so create it fresh.
              _loaded[1] && me != null
                  ? MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<MealBloc>()),
                        BlocProvider.value(
                            value: context.read<MealPoolBloc>()),
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
              // Tab 4 — Settings
              if (canManage)
                _loaded[4]
                    ? FlatSettingsPage(flat: widget.flat)
                    : const SizedBox.expand(),
            ],
          ),
        ),
        bottomNavigationBar: _BottomNavBar(
          items: navItems,
          selectedIndex: effectiveTab,
          onTap: _switchTab,
        ),
      ),
    ),  // closes BlocListener
    );  // closes PopScope
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == selectedIndex;

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
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.brand;
    final inactiveColor = context.textTerColor;

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
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: AppTypography.labelS.copyWith(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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
    required this.onReloadPending,
  });

  final FlatEntity flat;
  final FlatMemberEntity? me;
  final bool canManage;
  final ValueChanged<int> onTabSelect;
  final VoidCallback onReloadPending;

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
          onReloadPending();
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
                    onReloadPending: onReloadPending,
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 140.ms)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms),

              const SizedBox(height: AppSizing.sp24),

              // ── 3b. GETTING STARTED CHECKLIST ───────────────────────────
              // Shown until dismissed; role-aware (manager vs member).
              // The card returns SizedBox.shrink() when dismissed/loading,
              // so the SizedBox gap is wrapped in the same conditional to
              // avoid a phantom 16 px gap after dismissal.
              if (me != null)
                GettingStartedCard(
                  flat: flat,
                  me: me!,
                  canManage: canManage,
                  onTabSelect: onTabSelect,
                ).animate().fadeIn(duration: 350.ms, delay: 160.ms),

              // ── 4a. MONTH-CLOSE CHECKLIST (manager only) ─────────────
              // Appears when a previous month is unclosed. Lets the manager
              // approve/reject blocking expenses inline and then close the month.
              if (canManage)
                _MonthCloseChecklistCard(
                  flat: flat,
                  me: me,
                ).animate().fadeIn(duration: 400.ms, delay: 160.ms),
              if (canManage) const SizedBox(height: AppSizing.sp16),

              // ── 4b. PENDING ACTIONS ──────────────────────────────────────
              // Shown for all roles; the section hides itself when empty.
              _PendingActionsSection(
                flat: flat,
                me: me,
                canManage: canManage,
                onReloadPending: onReloadPending,
                onTabSelect: onTabSelect,
              ).animate().fadeIn(duration: 400.ms, delay: 180.ms),
              const SizedBox(height: AppSizing.sp24),

              // ── 5. MEMBERS GLIMPSE ───────────────────────────────────────
              SectionHeader(
                title: AppStrings.membersSection,
                actionLabel: AppStrings.viewAll,
                onAction: () =>
                    context.push(AppRoutes.flatMembers, extra: flat).then((_) {
                      if (context.mounted) {
                        context.read<FlatBloc>().add(
                          FlatRefreshRequested(flat.id),
                        );
                      }
                    }),
              ).animate().fadeIn(duration: 350.ms, delay: 220.ms),
              const SizedBox(height: AppSizing.sp12),
              _MembersGlimpse(
                flat: flat,
              ).animate().fadeIn(duration: 400.ms, delay: 240.ms),

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

  // void _showSettingsSheet(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: AppColors.surface,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(
  //           top: Radius.circular(AppSizing.radiusLg)),
  //     ),
  //     builder: (sheetCtx) => BlocProvider.value(
  //       value: context.read<ThemeCubit>(),
  //       child: _SettingsSheet(flat: flat, canManage: canManage),
  //     ),
  //   );
  // }

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
                    color: context.textPrimColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  flat.name,
                  style: AppTypography.bodyS.copyWith(
                    color: context.textSecColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Settings
          // IconButton(
          //   icon: const Icon(Icons.settings_outlined),
          //   color: AppColors.textSecondary,
          //   onPressed: () => context.push(AppRoutes.flatSettings, extra: flat),
          // ),

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
                          : context.textSecColor,
                    ),
                    onPressed: () => context.push(
                      AppRoutes.notifications,
                      extra: NotificationPageArgs(
                        flatId: flat.id,
                        canManage: me?.canManage ?? false,
                        isManager: me?.isManager ?? false,
                        myMemberId: me?.flatMemberId ?? '',
                      ),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: 4,
                      right: 4,
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
                          borderRadius: BorderRadius.circular(
                            AppSizing.rFull,
                          ),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
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
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onTabSelect(2),
                      child: _StatCard(
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: AppColors.brand,
                        label: 'Balance',
                        value: balanceText,
                        subtitle: summary?.isNegative == true
                            ? 'owed'
                            : 'available',
                        footnote: summary != null
                            ? 'Fixed ৳${summary.fixedContribution.toStringAsFixed(0)}/mo'
                            : null,
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
                        subtitle: flatWallet?.isNegative == true
                            ? 'deficit'
                            : 'available',
                      ),
                    ),
                  ),
                ],
              ),
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
                            context.read<FlatBloc>().add(
                              FlatRefreshRequested(flat.id),
                            );
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
                    child: _MealStatCard(myMemberId: me?.flatMemberId),
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
    this.footnote,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final String? footnote;

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
            style: AppTypography.amountL.copyWith(color: context.textPrimColor),
          ),
          Text(
            '$label · $subtitle',
            style: AppTypography.labelS.copyWith(color: context.textTerColor),
          ),
          if (footnote != null) ...[
            const SizedBox(height: 2),
            Text(
              footnote!,
              style: AppTypography.labelS.copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Meal stat card ────────────────────────────────────────────────────────────

class _MealStatCard extends StatelessWidget {
  const _MealStatCard({required this.myMemberId});
  final String? myMemberId;

  static const _bColor = Color(0xFFF59E0B); // breakfast amber
  static const _lColor = Color(0xFF10B981); // lunch green
  static const _dColor = Color(0xFF6C63FF); // dinner purple

  static String _monthAbbr(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];

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
          // Top row: icon + today's B/L/D chips
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _lColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizing.r12),
                ),
                child: const Icon(Icons.restaurant_rounded,
                    size: 18, color: _lColor),
              ),
              const Spacer(),
              BlocBuilder<MealBloc, MealState>(
                builder: (context, state) {
                  final logList = switch (state) {
                    MealDailyLoaded(:final logs) => logs.logs,
                    MealActionInProgress(:final logs) => logs.logs,
                    MealActionSuccess(:final logs) => logs.logs,
                    MealActionError(:final logs) => logs.logs,
                    _ => null,
                  };
                  final my = logList
                      ?.where((e) => e.flatMemberId == myMemberId)
                      .firstOrNull;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ShiftChip(label: 'B', on: my?.breakfast, color: _bColor),
                      const SizedBox(width: 4),
                      _ShiftChip(label: 'L', on: my?.lunch, color: _lColor),
                      const SizedBox(width: 4),
                      _ShiftChip(label: 'D', on: my?.dinner, color: _dColor),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSizing.sp8),
          // Monthly points
          BlocBuilder<MealPoolBloc, MealPoolState>(
            builder: (context, state) {
              double? pts;
              if (state is MealPoolLoaded && myMemberId != null) {
                pts = state.pool.memberBreakdown
                    .where((m) => m.flatMemberId == myMemberId)
                    .map((m) => m.totalPoints)
                    .firstOrNull;
              }
              return Text(
                pts != null ? '${pts.toStringAsFixed(1)} pts' : '--',
                style: AppTypography.amountL
                    .copyWith(color: context.textPrimColor),
              );
            },
          ),
          Text(
            'Meals · ${_monthAbbr(DateTime.now().month)}',
            style: AppTypography.labelS.copyWith(color: context.textTerColor),
          ),
        ],
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  const _ShiftChip({
    required this.label,
    required this.on,
    required this.color,
  });
  final String label;
  final bool? on; // null = not yet loaded
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isOn = on == true;
    return Container(
      width: 22,
      height: 20,
      decoration: BoxDecoration(
        color: on == null
            ? context.borderColor.withValues(alpha: 0.5)
            : isOn
                ? color.withValues(alpha: 0.15)
                : context.surfaceColor,
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: on == null
              ? context.borderColor
              : isOn
                  ? color
                  : context.textTerColor,
          height: 1,
        ),
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
    required this.onReloadPending,
  });

  final FlatEntity flat;
  final FlatMemberEntity? me;
  final bool canManage;
  final ValueChanged<int> onTabSelect;
  final VoidCallback onReloadPending;

  void _showQrSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusLg),
        ),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(AppSizing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSizing.md),
              decoration: BoxDecoration(
                color: sheetCtx.borderColor,
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              ),
            ),
            Text('Invite to ${flat.name}', style: AppTypography.titleLarge),
            const SizedBox(height: AppSizing.xs),
            Text(
              'Share this QR code or join code with others',
              style: AppTypography.bodySmall.copyWith(
                color: sheetCtx.textSecColor,
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
                  padding: const EdgeInsets.symmetric(vertical: AppSizing.sm),
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
        iconColor: const Color(0xFF6C63FF),
        onTap: () {
          if (me == null) return;
          context
              .push(
                AppRoutes.tasks,
                extra: TaskPageArgs(
                  flatId: flat.id,
                  canManage: canManage,
                  myMemberId: me!.flatMemberId,
                  members: flat.activeMembers,
                ),
              )
              .then((_) {
            if (context.mounted) onReloadPending();
          });
        },
      ),
      QuickActionButton(
        icon: Icons.report_problem_outlined,
        label: 'Complaints',
        iconColor: const Color(0xFFEF4444),
        onTap: () {
          if (me == null) return;
          context
              .push(
                AppRoutes.complaints,
                extra: ComplaintPageArgs(
                  flatId: flat.id,
                  canManage: canManage,
                  myMemberId: me!.flatMemberId,
                ),
              )
              .then((_) {
            if (context.mounted) onReloadPending();
          });
        },
      ),
      QuickActionButton(
        icon: Icons.bar_chart_rounded,
        label: 'Summary',
        iconColor: const Color(0xFF10B981),
        onTap: () {
          if (me == null) return;
          context.push(
            AppRoutes.summary,
            extra: SummaryPageArgs(
              flatId: flat.id,
              isManager: me?.isManager ?? false,
              myMemberId: me!.flatMemberId,
            ),
          );
        },
      ),
      QuickActionButton(
        icon: Icons.monetization_on_outlined,
        label: 'Fixed Exp.',
        iconColor: const Color(0xFFF59E0B),
        onTap: () => context
            .push(
              AppRoutes.flatExpenses,
              extra: {'flatId': flat.id, 'canManage': canManage},
            )
            .then((_) {
          if (context.mounted) onReloadPending();
        }),
      ),
      QuickActionButton(
        icon: Icons.qr_code_rounded,
        label: 'Invite',
        iconColor: const Color(0xFF3B82F6),
        onTap: () => _showQrSheet(context),
      ),
      QuickActionButton(
        icon: Icons.payments_outlined,
        label: 'Payment',
        iconColor: const Color(0xFF8B5CF6),
        onTap: () => context
            .push(
              AppRoutes.walletRequests,
              extra: WalletPageArgs(flatId: flat.id, canManage: canManage),
            )
            .then((_) {
          if (context.mounted) onReloadPending();
        }),
      ),
    ];

    // Buttons 9 & 10 differ by role
    final roleActions = canManage
        ? <Widget>[
            QuickActionButton(
              icon: Icons.history_edu_rounded,
              label: 'Audit',
              iconColor: const Color(0xFF0EA5E9),
              onTap: () => context.push(
                AppRoutes.auditLog,
                extra: AuditLogPageArgs(flatId: flat.id, members: flat.members),
              ),
            ),
            BlocBuilder<JoinRequestsBloc, JoinRequestsState>(
              builder: (context, reqState) {
                int pendingCount = 0;
                if (reqState is JoinRequestsLoaded) {
                  pendingCount = reqState.requests
                      .where((r) => r.isPending)
                      .length;
                }
                return QuickActionButton(
                  icon: Icons.group_add_outlined,
                  label: 'Requests',
                  badge: pendingCount,
                  iconColor: const Color(0xFFF97316),
                  onTap: () => context
                      .push(AppRoutes.flatRequests, extra: flat.id)
                      .then((_) {
                        // JoinRequestsBloc re-fetches internally after approve/decline;
                        // only refresh the flat to sync member count etc.
                        if (context.mounted) {
                          context.read<FlatBloc>().add(
                            FlatRefreshRequested(flat.id),
                          );
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
              iconColor: const Color(0xFF0EA5E9),
              onTap: () =>
                  context.push(AppRoutes.flatMembers, extra: flat).then((_) {
                    if (context.mounted) {
                      context.read<FlatBloc>().add(
                        FlatRefreshRequested(flat.id),
                      );
                    }
                  }),
            ),
            QuickActionButton(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              iconColor: const Color(0xFFF97316),
              onTap: () => context.push(
                AppRoutes.notifications,
                extra: NotificationPageArgs(
                  flatId: flat.id,
                  canManage: false,
                  isManager: false,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.pagePadding,
          ),
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

// ── 4a. Month-Close Checklist ─────────────────────────────────────────────────

class _MonthCloseChecklistCard extends StatelessWidget {
  const _MonthCloseChecklistCard({required this.flat, required this.me});

  final FlatEntity flat;
  final FlatMemberEntity? me;

  static const List<String> _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _shortDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${_months[dt.month].substring(0, 3)} ${dt.day}';
    } catch (_) {
      return '';
    }
  }

  static String _categoryLabel(String cat) {
    switch (cat) {
      case 'meal':       return 'Meal';
      case 'household':  return 'Household';
      case 'fixed':      return 'Fixed';
      default:           return cat;
    }
  }

  static IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'meal':      return Icons.restaurant_rounded;
      case 'household': return Icons.home_work_outlined;
      case 'fixed':     return Icons.repeat_rounded;
      default:          return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MonthCloseChecklistBloc, MonthCloseChecklistState>(
      listener: (context, state) {
        if (state is MonthCloseChecklistClosed) {
          AppSnackbar.success(
            context,
            '${state.monthName} ${state.year} closed! Check the summary.',
          );
        }
        if (state is MonthCloseChecklistError) {
          AppSnackbar.error(context, state.message);
          // Re-fetch to restore accurate state after error
          context
              .read<MonthCloseChecklistBloc>()
              .add(MonthCloseChecklistStatusRequested(flat.id));
        }
      },
      builder: (context, state) {
        // Resolve effective display state (error may carry previous state)
        final display = state is MonthCloseChecklistError
            ? (state.previous ?? state)
            : state;

        if (display is! MonthCloseChecklistPending &&
            display is! MonthCloseChecklistClosing) {
          return const SizedBox.shrink();
        }

        final pending   = display is MonthCloseChecklistPending ? display : null;
        final closing   = display is MonthCloseChecklistClosing;
        final closingState = display is MonthCloseChecklistClosing ? display : null;
        final month     = pending?.month ?? closingState?.month ?? 0;
        final year      = pending?.year  ?? closingState?.year  ?? 0;
        final monthName = pending?.monthName ?? closingState?.monthName ?? '';
        final expenses  = pending?.expenses ?? [];
        final canClose  = pending?.canClose ?? false;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
          child: Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(AppSizing.r16),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: AppColors.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizing.sp16, AppSizing.sp16, AppSizing.sp16, AppSizing.sp8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSizing.r12),
                        ),
                        child: const Icon(
                          Icons.lock_clock_outlined,
                          size: 18,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: AppSizing.sp12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Close $monthName $year',
                              style: AppTypography.labelL.copyWith(
                                color: context.textPrimColor,
                              ),
                            ),
                            Text(
                              expenses.isNotEmpty
                                  ? 'Resolve ${expenses.length} expense${expenses.length > 1 ? 's' : ''} before closing'
                                  : 'All clear — ready to close this month',
                              style: AppTypography.bodyS.copyWith(
                                color: context.textSecColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Expense checklist items ─────────────────────────────────
                if (expenses.isNotEmpty) ...[
                  Divider(
                    height: 1,
                    color: context.dividerColor,
                    indent: AppSizing.sp16,
                    endIndent: AppSizing.sp16,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizing.sp16, AppSizing.sp8, AppSizing.sp16, 0,
                    ),
                    child: Text(
                      'RESOLVE BEFORE CLOSING',
                      style: AppTypography.labelS.copyWith(
                        color: context.textTerColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...expenses.map((exp) {
                    final isActioning =
                        pending?.actioningExpenseId == exp.id;
                    return _ExpenseChecklistItem(
                      expense: exp,
                      isActioning: isActioning,
                      onApprove: isActioning
                          ? null
                          : () => context
                              .read<MonthCloseChecklistBloc>()
                              .add(MonthCloseChecklistExpenseApproved(
                                flatId: flat.id,
                                expenseId: exp.id,
                              )),
                      onReject: isActioning
                          ? null
                          : () => context
                              .read<MonthCloseChecklistBloc>()
                              .add(MonthCloseChecklistExpenseRejected(
                                flatId: flat.id,
                                expenseId: exp.id,
                              )),
                      categoryLabel: _categoryLabel(exp.expenseCategory),
                      categoryIcon: _categoryIcon(exp.expenseCategory),
                      dateLabel: _shortDate(exp.date),
                    );
                  }),
                ],

                // ── Ready state: all resolved ───────────────────────────────
                if (expenses.isEmpty) ...[
                  Divider(
                    height: 1,
                    color: context.dividerColor,
                    indent: AppSizing.sp16,
                    endIndent: AppSizing.sp16,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizing.sp16, AppSizing.sp12, AppSizing.sp16, 0,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: AppSizing.sp8),
                        Text(
                          'No pending expenses — month is ready to close',
                          style: AppTypography.bodyS.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Close button ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(AppSizing.sp16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (canClose && !closing)
                          ? () => context
                              .read<MonthCloseChecklistBloc>()
                              .add(MonthCloseChecklistCloseRequested(
                                flatId: flat.id,
                                month: month,
                                year: year,
                              ))
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor:
                            AppColors.warning.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizing.sp12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizing.r12),
                        ),
                        elevation: 0,
                      ),
                      child: closing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              canClose
                                  ? 'Close $monthName $year'
                                  : 'Resolve expenses to close',
                              style: AppTypography.labelM.copyWith(
                                color: canClose
                                    ? AppColors.white
                                    : AppColors.white.withValues(alpha: 0.6),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExpenseChecklistItem extends StatelessWidget {
  const _ExpenseChecklistItem({
    required this.expense,
    required this.isActioning,
    required this.onApprove,
    required this.onReject,
    required this.categoryLabel,
    required this.categoryIcon,
    required this.dateLabel,
  });

  final ExpenseEntity expense;
  final bool isActioning;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final String categoryLabel;
  final IconData categoryIcon;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSizing.sp16, AppSizing.sp4, AppSizing.sp16, 0),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.sp12,
        vertical: AppSizing.sp8,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizing.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Category icon
              Icon(categoryIcon, size: 14, color: context.textSecColor),
              const SizedBox(width: AppSizing.sp4),
              Text(
                categoryLabel,
                style: AppTypography.labelS.copyWith(
                    color: context.textSecColor),
              ),
              const Spacer(),
              // Amount
              Text(
                '৳${expense.amount.toStringAsFixed(expense.amount % 1 == 0 ? 0 : 2)}',
                style: AppTypography.labelL.copyWith(
                    color: context.textPrimColor),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  [
                    if (expense.description != null &&
                        expense.description!.isNotEmpty)
                      expense.description!,
                    'by ${expense.paidByName}',
                    if (dateLabel.isNotEmpty) '· $dateLabel',
                  ].join(' '),
                  style: AppTypography.bodyS.copyWith(
                      color: context.textTerColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizing.sp8),
          // Action buttons or loading indicator
          if (isActioning)
            const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brand,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onApprove,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: BorderSide(
                          color: AppColors.success.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizing.sp4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizing.r8),
                      ),
                    ),
                    child: Text(
                      'Approve',
                      style: AppTypography.labelS.copyWith(
                          color: AppColors.success),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizing.sp8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizing.sp4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizing.r8),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      style: AppTypography.labelS.copyWith(
                          color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── 4b. Pending Actions ───────────────────────────────────────────────────────

class _PendingActionsSection extends StatelessWidget {
  const _PendingActionsSection({
    required this.flat,
    required this.me,
    required this.canManage,
    required this.onReloadPending,
    required this.onTabSelect,
  });

  final FlatEntity flat;
  final FlatMemberEntity? me;
  final bool canManage;
  final VoidCallback onReloadPending;
  final ValueChanged<int> onTabSelect;

  @override
  Widget build(BuildContext context) {
    if (me == null) return const SizedBox.shrink();
    final myMemberId = me!.flatMemberId;

    final cards = <Widget>[];

    if (canManage) {
      // ── Manager cards ─────────────────────────────────────────────────────

      // 1. Payments submitted by members, awaiting manager verification
      final paymentsState = context.watch<PaymentsBloc>().state;
      if (paymentsState is PaymentsLoaded &&
          paymentsState.payments.isNotEmpty) {
        final count = paymentsState.payments.length;
        cards.add(_PendingCard(
          icon: Icons.verified_rounded,
          accentColor: AppColors.success,
          title: '$count payment${count > 1 ? 's' : ''} to verify',
          subtitle: 'Submitted by members, awaiting your review',
          actionLabel: 'Verify',
          onAction: () => context
              .push(
                AppRoutes.walletRequests,
                extra: WalletPageArgs(flatId: flat.id, canManage: true, initialTab: 1),
              )
              .then((_) {
            if (context.mounted) onReloadPending();
          }),
        ));
      }

      // 2. Unapproved expenses
      final expenseState = context.watch<ExpenseBloc>().state;
      if (expenseState is ExpenseListLoaded) {
        final total = (expenseState.pagination['total'] as int?) ??
            expenseState.expenses.length;
        if (total > 0) {
          cards.add(_PendingCard(
            icon: Icons.receipt_long_rounded,
            accentColor: AppColors.info,
            title: '$total unapproved expense${total > 1 ? 's' : ''}',
            subtitle: 'Awaiting your approval',
            actionLabel: 'Review',
            // Navigate to the Expenses tab (Tab 3) in the IndexedStack
            onAction: () => onTabSelect(3),
          ));
        }
      }

      // 3. Pending join requests
      final joinState = context.watch<JoinRequestsBloc>().state;
      final joinCount = joinState is JoinRequestsLoaded
          ? joinState.requests.where((r) => r.isPending).length
          : 0;
      if (joinCount > 0) {
        cards.add(_PendingCard(
          icon: Icons.group_add_outlined,
          accentColor: AppColors.warning,
          title: '$joinCount join request${joinCount > 1 ? 's' : ''}',
          subtitle: 'Awaiting your approval',
          actionLabel: 'Review',
          onAction: () => context
              .push(AppRoutes.flatRequests, extra: flat.id)
              .then((_) {
            // JoinRequestsBloc self-refreshes; only sync flat member count.
            if (context.mounted) {
              context.read<FlatBloc>().add(FlatRefreshRequested(flat.id));
            }
          }),
        ));
      }

      // 4. Open complaints across the flat
      final complaintState = context.watch<ComplaintBloc>().state;
      if (complaintState is ComplaintListLoaded &&
          complaintState.complaints.isNotEmpty) {
        final total = (complaintState.pagination['total'] as int?) ??
            complaintState.complaints.length;
        if (total > 0) {
          cards.add(_PendingCard(
            icon: Icons.report_problem_outlined,
            accentColor: AppColors.error,
            title: '$total open complaint${total > 1 ? 's' : ''}',
            subtitle: 'Needs your attention',
            actionLabel: 'View',
            onAction: () => context
                .push(
                  AppRoutes.complaints,
                  extra: ComplaintPageArgs(
                    flatId: flat.id,
                    canManage: true,
                    myMemberId: myMemberId,
                  ),
                )
                .then((_) {
              if (context.mounted) onReloadPending();
            }),
          ));
        }
      }
    } else {
      // ── Member cards ──────────────────────────────────────────────────────

      // 1. Payment requests directed at this member (admin asking them to pay)
      final walletState = context.watch<WalletBloc>().state;
      final walletSummary = switch (walletState) {
        WalletSummaryLoaded(summary: final s) => s,
        WalletActionLoading(summary: final s) => s,
        WalletPaymentSubmitSuccess(summary: final s) => s,
        WalletError(summary: final s) when s != null => s,
        _ => null,
      };
      if (walletSummary != null &&
          walletSummary.pendingPaymentRequests.isNotEmpty) {
        final count = walletSummary.pendingPaymentRequests.length;
        cards.add(_PendingCard(
          icon: Icons.payments_outlined,
          accentColor: AppColors.warning,
          title: '$count pending payment request${count > 1 ? 's' : ''}',
          subtitle: 'You have been requested to pay',
          actionLabel: 'View',
          onAction: () => context
              .push(
                AppRoutes.walletRequests,
                extra: WalletPageArgs(flatId: flat.id, canManage: false),
              )
              .then((_) {
            if (context.mounted) onReloadPending();
          }),
        ));
      }

      // 2. This member's open complaints
      final complaintState = context.watch<ComplaintBloc>().state;
      if (complaintState is ComplaintListLoaded &&
          complaintState.complaints.isNotEmpty) {
        final total = (complaintState.pagination['total'] as int?) ??
            complaintState.complaints.length;
        if (total > 0) {
          cards.add(_PendingCard(
            icon: Icons.report_problem_outlined,
            accentColor: AppColors.info,
            title: '$total open complaint${total > 1 ? 's' : ''}',
            subtitle:
                'Your complaint${total > 1 ? 's are' : ' is'} awaiting resolution',
            actionLabel: 'Track',
            onAction: () => context
                .push(
                  AppRoutes.complaints,
                  extra: ComplaintPageArgs(
                    flatId: flat.id,
                    canManage: false,
                    myMemberId: myMemberId,
                  ),
                )
                .then((_) {
              if (context.mounted) onReloadPending();
            }),
          ));
        }
      }
    }

    // ── Common card (all roles): tasks assigned to this member ─────────────
    final taskState = context.watch<TaskBloc>().state;
    if (taskState is TaskListLoaded && taskState.tasks.isNotEmpty) {
      final total = (taskState.pagination['total'] as int?) ??
          taskState.tasks.length;
      if (total > 0) {
        cards.add(_PendingCard(
          icon: Icons.task_alt_rounded,
          accentColor: AppColors.brand,
          title: '$total pending task${total > 1 ? 's' : ''} assigned to you',
          subtitle: 'Task${total > 1 ? 's' : ''} waiting to be completed',
          actionLabel: 'View',
          onAction: () => context
              .push(
                AppRoutes.tasks,
                extra: TaskPageArgs(
                  flatId: flat.id,
                  canManage: canManage,
                  myMemberId: myMemberId,
                  members: flat.activeMembers,
                ),
              )
              .then((_) {
            if (context.mounted) onReloadPending();
          }),
        ));
      }
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(eyebrow: 'action needed', title: 'Pending'),
        const SizedBox(height: AppSizing.sp12),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
          child: Column(
            children: cards
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizing.sp8),
                    child: c,
                  ),
                )
                .toList(),
          ),
        ),
      ],
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
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.r16),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
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
          style: AppTypography.bodyS.copyWith(color: context.textSecColor),
        ),
        trailing: TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: accentColor,
            padding: const EdgeInsets.symmetric(horizontal: AppSizing.sp12),
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

// class _SettingsSheet extends StatelessWidget {
//   const _SettingsSheet({required this.flat, required this.canManage});

//   final FlatEntity flat;
//   final bool canManage;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.fromLTRB(
//         AppSizing.pagePadding,
//         AppSizing.md,
//         AppSizing.pagePadding,
//         MediaQuery.of(context).viewInsets.bottom + AppSizing.pagePadding,
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // drag handle
//           Center(
//             child: Container(
//               width: 40,
//               height: 4,
//               margin: const EdgeInsets.only(bottom: AppSizing.md),
//               decoration: BoxDecoration(
//                 color: AppColors.border,
//                 borderRadius: BorderRadius.circular(AppSizing.radiusFull),
//               ),
//             ),
//           ),
//           Text('Settings', style: AppTypography.headlineSmall),
//           const SizedBox(height: AppSizing.md),

//           // Flat Settings (manager only)
//           if (canManage) ...[
//             _SettingsTile(
//               icon: Icons.home_work_outlined,
//               label: 'Flat Settings',
//               subtitle: 'Name, photo, meal config',
//               onTap: () {
//                 Navigator.pop(context);
//               },
//             ),
//             const SizedBox(height: AppSizing.sm),
//           ],

//           // Theme
//           Text(
//             'Theme',
//             style: AppTypography.labelM.copyWith(
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: AppSizing.xs),
//           BlocBuilder<ThemeCubit, ThemeState>(
//             builder: (context, state) {
//               return Row(
//                 children: [
//                   _ThemeOption(
//                     icon: Icons.light_mode_rounded,
//                     label: 'Light',
//                     selected: state.mode == ThemeMode.light,
//                     onTap: () =>
//                         context.read<ThemeCubit>().setTheme(ThemeMode.light),
//                   ),
//                   const SizedBox(width: AppSizing.sm),
//                   _ThemeOption(
//                     icon: Icons.brightness_auto_rounded,
//                     label: 'System',
//                     selected: state.mode == ThemeMode.system,
//                     onTap: () =>
//                         context.read<ThemeCubit>().setTheme(ThemeMode.system),
//                   ),
//                 ],
//               );
//             },
//           ),
//           const SizedBox(height: AppSizing.sm),
//         ],
//       ),
//     );
//   }
// }

// class _SettingsTile extends StatelessWidget {
//   const _SettingsTile({
//     required this.icon,
//     required this.label,
//     required this.subtitle,
//     required this.onTap,
//   });

//   final IconData icon;
//   final String label;
//   final String subtitle;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       onTap: onTap,
//       contentPadding: EdgeInsets.zero,
//       leading: Container(
//         width: 40,
//         height: 40,
//         decoration: BoxDecoration(
//           color: AppColors.brand.withValues(alpha: 0.1),
//           borderRadius: BorderRadius.circular(AppSizing.radiusMd),
//         ),
//         child: Icon(icon, size: 20, color: AppColors.brand),
//       ),
//       title: Text(label, style: AppTypography.titleMedium),
//       subtitle: Text(
//         subtitle,
//         style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
//       ),
//       trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
//     );
//   }
// }

// class _ThemeOption extends StatelessWidget {
//   const _ThemeOption({
//     required this.icon,
//     required this.label,
//     required this.selected,
//     required this.onTap,
//   });

//   final IconData icon;
//   final String label;
//   final bool selected;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: GestureDetector(
//         onTap: onTap,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           padding: const EdgeInsets.symmetric(vertical: AppSizing.sm),
//           decoration: BoxDecoration(
//             color: selected
//                 ? AppColors.brand.withValues(alpha: 0.1)
//                 : context.cardColor,
//             borderRadius: BorderRadius.circular(AppSizing.radiusMd),
//             border: Border.all(
//               color: selected ? AppColors.brand : AppColors.border,
//               width: selected ? 1.5 : 1,
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 icon,
//                 size: 20,
//                 color: selected ? AppColors.brand : AppColors.textSecondary,
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 label,
//                 style: AppTypography.labelS.copyWith(
//                   color: selected ? AppColors.brand : AppColors.textSecondary,
//                   fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
