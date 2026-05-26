import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_card.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/widgets/quick_action_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../audit_log/presentation/args/audit_log_page_args.dart';
import '../../../complaint/presentation/args/complaint_page_args.dart';
import '../../../expense/presentation/args/expense_list_args.dart';
import '../../../meal/presentation/args/meal_page_args.dart';
import '../../../notification/presentation/args/notification_page_args.dart';
import '../../../notification/presentation/bloc/notification_bloc.dart';
import '../../../notification/presentation/bloc/notification_state.dart';
import '../../../summary/presentation/args/summary_page_args.dart';
import '../../../task/presentation/args/task_page_args.dart';
import '../../../wallet/presentation/args/wallet_page_args.dart';
import '../../../wallet/presentation/bloc/wallet/wallet_bloc.dart';
import '../../domain/entities/flat_entity.dart';
import '../../domain/entities/flat_member_entity.dart';
import '../bloc/flat_bloc.dart';
import '../bloc/join_requests_bloc.dart';
import '../widgets/expense_tile.dart';
import '../widgets/member_tile.dart';

class FlatHomeView extends StatelessWidget {
  final FlatEntity flat;

  const FlatHomeView({super.key, required this.flat});

  FlatMemberEntity? _myMember(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return null;
    return flat.memberByUserId(authState.user.id);
  }

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
    final me = _myMember(context);
    final canManage = me?.canManage ?? false;

    // Build wallet args once so both the hero card and shell tab can use them
    final walletArgs = WalletPageArgs(flatId: flat.id, canManage: canManage);

    return BlocListener<FlatBloc, FlatState>(
      listener: (context, state) {
        if (state is FlatError) AppSnackbar.error(context, state.message);
      },
      child: MainShell(
        selectedIndex: 0,
        walletPageArgs: walletArgs,
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () async {
            context.read<FlatBloc>().add(FlatRefreshRequested(flat.id));
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. HEADER ──────────────────────────────────────────
                    _HomeHeader(
                      flat: flat,
                      me: me,
                      greeting: _greeting(),
                      greetingEmoji: _greetingEmoji(),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: -0.1, end: 0, duration: 300.ms),

                    const SizedBox(height: AppSizing.sp16),

                    // ── 2. WALLET HERO CARD ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.pagePadding,
                      ),
                      child: _WalletHeroCard(
                        flat: flat,
                        me: me,
                        canManage: canManage,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 80.ms)
                        .slideY(begin: 0.08, end: 0, duration: 400.ms),

                    const SizedBox(height: AppSizing.sp24),

                    // ── 3. QUICK ACTIONS ───────────────────────────────────
                    _QuickActionsRow(
                      flat: flat,
                      me: me,
                      canManage: canManage,
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 140.ms)
                        .slideY(begin: 0.08, end: 0, duration: 400.ms),

                    const SizedBox(height: AppSizing.sp24),

                    // ── 4. THIS MONTH STATS ────────────────────────────────
                    SectionHeader(
                      eyebrow: 'overview',
                      title: 'This Month',
                    )
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 180.ms),
                    const SizedBox(height: AppSizing.sp12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.pagePadding,
                      ),
                      child: _ThisMonthGrid(flat: flat, me: me),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideY(begin: 0.08, end: 0, duration: 400.ms),

                    const SizedBox(height: AppSizing.sp24),

                    // ── 5. PENDING ACTIONS (manager only) ─────────────────
                    if (canManage) ...[
                      _PendingActionsSection(flat: flat)
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 220.ms),
                      const SizedBox(height: AppSizing.sp24),
                    ],

                    // ── 6. MEMBERS GLIMPSE ─────────────────────────────────
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
                        .fadeIn(duration: 350.ms, delay: 240.ms),
                    const SizedBox(height: AppSizing.sp12),
                    _MembersRow(flat: flat, me: me)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 260.ms),

                    const SizedBox(height: AppSizing.sp24),

                    // ── 7. FIXED EXPENSES ──────────────────────────────────
                    SectionHeader(
                      title: AppStrings.expensesSection,
                      actionLabel: canManage
                          ? AppStrings.manageLabel
                          : AppStrings.viewAll,
                      onAction: () => context.push(
                        AppRoutes.flatExpenses,
                        extra: {
                          'flatId': flat.id,
                          'canManage': canManage,
                        },
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 280.ms),
                    const SizedBox(height: AppSizing.sp12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.pagePadding,
                      ),
                      child: flat.fixedExpenses.isEmpty
                          ? Text(
                              AppStrings.noExpenses,
                              style: AppTypography.bodyM.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            )
                          : Column(
                              children: flat.fixedExpenses
                                  .take(3)
                                  .map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSizing.sp8,
                                      ),
                                      child: ExpenseTile(expense: e),
                                    ),
                                  )
                                  .toList(),
                            ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 300.ms),

                    const SizedBox(height: AppSizing.sp48),
                  ],
                ),
              ),
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
    required this.greeting,
    required this.greetingEmoji,
  });

  final FlatEntity flat;
  final FlatMemberEntity? me;
  final String greeting;
  final String greetingEmoji;

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

          // Settings (manager)
          if (me?.canManage ?? false)
            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () => context.push(AppRoutes.flatSettings, extra: flat),
            ),
        ],
      ),
    );
  }
}

// ── 2. Wallet Hero Card ───────────────────────────────────────────────────────

class _WalletHeroCard extends StatelessWidget {
  const _WalletHeroCard({
    required this.flat,
    required this.me,
    required this.canManage,
  });

  final FlatEntity flat;
  final FlatMemberEntity? me;
  final bool canManage;

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

        return GestureDetector(
          onTap: () => context.push(
            AppRoutes.walletHome,
            extra: WalletPageArgs(flatId: flat.id, canManage: canManage),
          ),
          child: GradientCard(
            gradient: AppColors.brandGradient,
            radius: AppSizing.r24,
            padding: const EdgeInsets.all(AppSizing.sp24),
            shadows: AppColors.shadowBrand,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overline label
                Text(
                  'YOUR BALANCE',
                  style: AppTypography.overline.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: AppSizing.sp8),

                // Balance amount
                if (summary == null)
                  const SizedBox(
                    height: 44,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else ...[
                  Text(
                    '${summary.isNegative ? '−' : ''}৳${summary.walletBalance.abs().toStringAsFixed(0)}',
                    style: AppTypography.amountXL.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  if (summary.hasPendingRequests) ...[
                    const SizedBox(height: AppSizing.sp4),
                    Text(
                      '${summary.pendingPaymentRequests.length} pending request${summary.pendingPaymentRequests.length > 1 ? 's' : ''}',
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: AppSizing.sp20),

                // Ghost action pills
                Row(
                  children: [
                    _GhostPill(
                      icon: Icons.add_rounded,
                      label: 'Deposit',
                      onTap: () => context.push(
                        AppRoutes.walletHome,
                        extra: WalletPageArgs(
                          flatId: flat.id,
                          canManage: canManage,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizing.sp8),
                    _GhostPill(
                      icon: Icons.send_rounded,
                      label: 'Request',
                      onTap: () => context.push(
                        AppRoutes.walletRequests,
                        extra: WalletPageArgs(
                          flatId: flat.id,
                          canManage: canManage,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizing.sp8),
                    _GhostPill(
                      icon: Icons.history_rounded,
                      label: 'History',
                      onTap: () => context.push(
                        AppRoutes.walletTransactions,
                        extra: flat.id,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GhostPill extends StatelessWidget {
  const _GhostPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.sp12,
          vertical: AppSizing.sp8,
        ),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppSizing.rFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.white),
            const SizedBox(width: AppSizing.sp4),
            Text(
              label,
              style: AppTypography.labelS.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
  });

  final FlatEntity flat;
  final FlatMemberEntity? me;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: AppSizing.sp12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
          child: Row(
            children: [
              QuickActionButton(
                icon: Icons.restaurant_rounded,
                label: 'Meals',
                onTap: () {
                  if (me == null) return;
                  context.push(
                    AppRoutes.meals,
                    extra: MealPageArgs(
                      flatId: flat.id,
                      canManage: canManage,
                      myMemberId: me!.flatMemberId,
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSizing.sp12),
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
              const SizedBox(width: AppSizing.sp12),
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
              const SizedBox(width: AppSizing.sp12),
              QuickActionButton(
                icon: Icons.receipt_long_outlined,
                label: 'Expenses',
                onTap: () => context.push(
                  AppRoutes.expenses,
                  extra: ExpenseListArgs(
                    flatId: flat.id,
                    canManage: canManage,
                  ),
                ),
              ),
              const SizedBox(width: AppSizing.sp12),
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
              const SizedBox(width: AppSizing.sp12),
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
              if (canManage) ...[
                const SizedBox(width: AppSizing.sp12),
                QuickActionButton(
                  icon: Icons.history_edu_rounded,
                  label: 'Audit',
                  onTap: () => context.push(
                    AppRoutes.auditLog,
                    extra: AuditLogPageArgs(flatId: flat.id),
                  ),
                ),
                const SizedBox(width: AppSizing.sp12),
                // Join-request badge
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
                        if (context.mounted) {
                          context.read<JoinRequestsBloc>().add(
                            JoinRequestsLoadRequested(flat.id),
                          );
                          context
                              .read<FlatBloc>()
                              .add(FlatRefreshRequested(flat.id));
                        }
                      }),
                    );
                  },
                ),
              ],
              // Invite / QR code
              const SizedBox(width: AppSizing.sp12),
              QuickActionButton(
                icon: Icons.qr_code_rounded,
                label: 'Invite',
                onTap: () => _showQrSheet(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
}

// ── 4. This Month Grid ────────────────────────────────────────────────────────

class _ThisMonthGrid extends StatelessWidget {
  const _ThisMonthGrid({required this.flat, required this.me});

  final FlatEntity flat;
  final FlatMemberEntity? me;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Meal stat card
        Expanded(
          child: _StatMiniCard(
            emoji: '🍽️',
            label: 'Members',
            value: '${flat.activeMembers.length}',
            subtitle: 'active',
            accentColor: AppColors.info,
          ),
        ),
        const SizedBox(width: AppSizing.sp12),
        // Fixed contribution card
        Expanded(
          child: BlocBuilder<WalletBloc, WalletState>(
            builder: (context, walletState) {
              final summary = switch (walletState) {
                WalletSummaryLoaded(summary: final s) => s,
                WalletActionLoading(summary: final s) => s,
                WalletPaymentSubmitSuccess(summary: final s) => s,
                WalletError(summary: final s) when s != null => s,
                _ => null,
              };

              final paid = summary?.hasPaidFixedThisMonth ?? false;
              final contribution = me?.fixedContribution ?? 0;

              return _StatMiniCard(
                emoji: '💰',
                label: 'Contribution',
                value: '৳${contribution.toStringAsFixed(0)}',
                subtitle: contribution > 0 ? (paid ? 'paid' : 'due') : 'none',
                accentColor:
                    paid ? AppColors.success : AppColors.warning,
                showStatus: contribution > 0,
                statusPaid: paid,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    this.showStatus = false,
    this.statusPaid = false,
  });

  final String emoji;
  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;
  final bool showStatus;
  final bool statusPaid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.sp16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizing.r16),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const Spacer(),
              if (showStatus)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.sp8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (statusPaid ? AppColors.success : AppColors.warning)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizing.rFull),
                  ),
                  child: Text(
                    statusPaid ? 'Paid' : 'Due',
                    style: AppTypography.labelS.copyWith(
                      color: statusPaid
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
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

// ── 5. Pending Actions (manager) ──────────────────────────────────────────────

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
                title: '$pendingCount join request${pendingCount > 1 ? 's' : ''}',
                subtitle: 'Awaiting your approval',
                actionLabel: 'Review',
                onAction: () => context
                    .push(AppRoutes.flatRequests, extra: flat.id)
                    .then((_) {
                  if (context.mounted) {
                    context.read<JoinRequestsBloc>().add(
                      JoinRequestsLoadRequested(flat.id),
                    );
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
          style: AppTypography.bodyS.copyWith(color: AppColors.textSecondary),
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

// ── 6. Members Row ────────────────────────────────────────────────────────────

class _MembersRow extends StatelessWidget {
  const _MembersRow({required this.flat, required this.me});

  final FlatEntity flat;
  final FlatMemberEntity? me;

  @override
  Widget build(BuildContext context) {
    // Show up to 5 in the horizontal row; rest shown via "View All"
    final members = flat.activeMembers.take(5).toList();

    return Column(
      children: [
        // Horizontal avatar row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
          child: Row(
            children: members.map((m) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSizing.sp16),
                child: _MemberChip(member: m),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSizing.sp16),
        // Full list preview (top 3)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
          child: Column(
            children: flat.activeMembers
                .take(3)
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizing.sp8),
                    child: MemberTile(member: m),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.member});

  final FlatMemberEntity member;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppAvatar(
          name: member.name,
          radius: AppSizing.avatar40 / 2,
          backgroundColor: AppColors.brand.withValues(alpha: 0.1),
          textColor: AppColors.brand,
        ),
        const SizedBox(height: AppSizing.sp4),
        Text(
          member.name.split(' ').first,
          style: AppTypography.labelS.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (member.fixedContribution > 0)
          Text(
            '৳${member.fixedContribution.toStringAsFixed(0)}',
            style: AppTypography.labelS.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
      ],
    );
  }
}
