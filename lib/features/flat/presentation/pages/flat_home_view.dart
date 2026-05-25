import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../expense/presentation/args/expense_list_args.dart';
import '../../../meal/presentation/args/meal_page_args.dart';
import '../../../summary/presentation/args/summary_page_args.dart';
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

  @override
  Widget build(BuildContext context) {
    final me = _myMember(context);
    final canManage = me?.canManage ?? false;

    return BlocListener<FlatBloc, FlatState>(
      listener: (context, state) {
        if (state is FlatError) AppSnackbar.error(context, state.message);
      },
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          context.read<FlatBloc>().add(FlatRefreshRequested(flat.id));
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: CustomScrollView(
          slivers: [
            // --- App Bar ---
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.primary,
              actions: [
                if (canManage)
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.white,
                    ),
                    onPressed: () =>
                        context.push(AppRoutes.flatSettings, extra: flat),
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.person_outline,
                    color: AppColors.white,
                  ),
                  onPressed: () => context.push(AppRoutes.profile),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSizing.pagePadding,
                    80,
                    AppSizing.pagePadding,
                    AppSizing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          AppAvatar(
                            imageUrl: flat.photoUrl,
                            name: flat.name,
                            radius: 28,
                            backgroundColor:
                                AppColors.white.withValues(alpha: 0.2),
                            textColor: AppColors.white,
                          ),
                          const SizedBox(width: AppSizing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  flat.name,
                                  style:
                                      AppTypography.headlineMedium.copyWith(
                                    color: AppColors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (flat.address != null)
                                  Text(
                                    flat.address!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.white
                                          .withValues(alpha: 0.8),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizing.sm),
                      GestureDetector(
                        onTap: () => _showQrSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              AppSizing.radiusFull,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.qr_code,
                                size: 14,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${AppStrings.joinCode}: ${flat.joinCode}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.copy,
                                size: 12,
                                color: AppColors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizing.md),

                  // --- Financial summary card (wallet balance + flat balance + contribution status) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizing.pagePadding,
                    ),
                    child: _FinancialSummaryCard(
                      flat: flat,
                      me: me,
                      canManage: canManage,
                    ),
                  ),

                  const SizedBox(height: AppSizing.md),

                  // --- Stats row ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizing.pagePadding,
                    ),
                    child: Row(
                      children: [
                        _StatCard(
                          label: AppStrings.memberCount,
                          value: '${flat.activeMembers.length}',
                          icon: Icons.group_outlined,
                        ),
                        const SizedBox(width: AppSizing.sm),
                        _StatCard(
                          label: AppStrings.totalExpenses,
                          value: '৳${flat.totalFixedExpenses.toStringAsFixed(0)}',
                          icon: Icons.receipt_long_outlined,
                        ),
                        if (me != null) ...[
                          const SizedBox(width: AppSizing.sm),
                          _StatCard(
                            label: AppStrings.myContribution,
                            value: '৳${me.fixedContribution.toStringAsFixed(0)}',
                            icon: Icons.currency_exchange_outlined,
                            accent: true,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizing.lg),

                  // --- Quick actions ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizing.pagePadding,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: AppStrings.expensesActionLabel,
                            icon: Icons.receipt_outlined,
                            onTap: () => context.push(
                              AppRoutes.expenses,
                              extra: ExpenseListArgs(
                                flatId: flat.id,
                                canManage: canManage,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizing.md),
                        Expanded(
                          child: _ActionButton(
                            label: 'Members',
                            icon: Icons.group_outlined,
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
                        ),
                        const SizedBox(width: AppSizing.md),
                        Expanded(
                          child: _ActionButton(
                            label: 'Meals',
                            icon: Icons.restaurant_outlined,
                            onTap: () {
                              final member = me;
                              if (member == null) return;
                              context.push(
                                AppRoutes.meals,
                                extra: MealPageArgs(
                                  flatId: flat.id,
                                  canManage: canManage,
                                  myMemberId: member.flatMemberId,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSizing.md),
                        Expanded(
                          child: _ActionButton(
                            label: 'Invite',
                            icon: Icons.qr_code_rounded,
                            onTap: () => _showQrSheet(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizing.pagePadding,
                    ),
                    child: _ActionButton(
                      label: 'Monthly Summary',
                      icon: Icons.bar_chart_rounded,
                      onTap: () {
                        final member = me;
                        if (member == null) return;
                        context.push(
                          AppRoutes.summary,
                          extra: SummaryPageArgs(
                            flatId: flat.id,
                            isManager: canManage,
                            myMemberId: member.flatMemberId,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSizing.lg),

                  // --- Manager actions ---
                  if (canManage) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.pagePadding,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: BlocBuilder<JoinRequestsBloc,
                                JoinRequestsState>(
                              builder: (context, reqState) {
                                int? pendingCount;
                                if (reqState is JoinRequestsLoaded) {
                                  pendingCount = reqState.requests
                                      .where((r) => r.isPending)
                                      .length;
                                  if (pendingCount == 0) pendingCount = null;
                                }
                                return _ActionButton(
                                  label: AppStrings.joinRequestsLabel,
                                  icon: Icons.group_add_outlined,
                                  badge: pendingCount,
                                  onTap: () {
                                    context
                                        .push(
                                          AppRoutes.flatRequests,
                                          extra: flat.id,
                                        )
                                        .then((_) {
                                      if (context.mounted) {
                                        context.read<JoinRequestsBloc>().add(
                                          JoinRequestsLoadRequested(flat.id),
                                        );
                                        context.read<FlatBloc>().add(
                                          FlatRefreshRequested(flat.id),
                                        );
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: AppSizing.md),
                          Expanded(
                            child: _ActionButton(
                              label: AppStrings.fixedExpensesTitle,
                              icon: Icons.receipt_long_outlined,
                              onTap: () => context.push(
                                AppRoutes.flatExpenses,
                                extra: {
                                  'flatId': flat.id,
                                  'canManage': canManage,
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizing.lg),
                  ],

                  // --- Members section ---
                  _SectionHeader(
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
                  ),
                  const SizedBox(height: AppSizing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizing.pagePadding,
                    ),
                    child: Column(
                      children: flat.activeMembers
                          .take(3)
                          .map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSizing.sm,
                              ),
                              child: MemberTile(member: m),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: AppSizing.lg),

                  // --- Fixed expenses section ---
                  _SectionHeader(
                    title: AppStrings.expensesSection,
                    actionLabel: canManage
                        ? AppStrings.manageLabel
                        : AppStrings.viewAll,
                    onAction: () => context.push(
                      AppRoutes.flatExpenses,
                      extra: {'flatId': flat.id, 'canManage': canManage},
                    ),
                  ),
                  const SizedBox(height: AppSizing.sm),
                  if (flat.fixedExpenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.pagePadding,
                      ),
                      child: Text(
                        AppStrings.noExpenses,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.pagePadding,
                      ),
                      child: Column(
                        children: flat.fixedExpenses
                            .take(3)
                            .map(
                              (e) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSizing.sm),
                                child: ExpenseTile(expense: e),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: AppSizing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
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
            Text('Invite to ${flat.name}', style: AppTypography.titleLarge),
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
}

// ── Financial summary card ────────────────────────────────────────────────────

class _FinancialSummaryCard extends StatelessWidget {
  const _FinancialSummaryCard({
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
        final flatWallet = switch (walletState) {
          WalletSummaryLoaded(flatWallet: final fw) => fw,
          WalletActionLoading(flatWallet: final fw) => fw,
          WalletPaymentSubmitSuccess(flatWallet: final fw) => fw,
          _ => null,
        };

        if (summary == null) {
          return Container(
            padding: const EdgeInsets.all(AppSizing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }

        final isNeg = summary.isNegative;
        final balanceColor = isNeg ? AppColors.error : AppColors.success;
        final paid = summary.hasPaidFixedThisMonth;

        return GestureDetector(
          onTap: () => context.push(
            AppRoutes.walletHome,
            extra: WalletPageArgs(flatId: flat.id, canManage: canManage),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSizing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isNeg
                    ? [
                        AppColors.error.withValues(alpha: 0.08),
                        AppColors.error.withValues(alpha: 0.04),
                      ]
                    : [
                        AppColors.primary.withValues(alpha: 0.08),
                        AppColors.primary.withValues(alpha: 0.03),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              border: Border.all(
                color: isNeg
                    ? AppColors.error.withValues(alpha: 0.3)
                    : AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: balance + contribution status badge
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Wallet',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${isNeg ? '−' : ''}৳${summary.walletBalance.abs().toStringAsFixed(0)}',
                            style: AppTypography.headlineMedium.copyWith(
                              color: balanceColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Contribution status badge
                    if (me != null && me!.fixedContribution > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: paid
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.warning.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusFull),
                          border: Border.all(
                            color: paid
                                ? AppColors.success.withValues(alpha: 0.4)
                                : AppColors.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              paid
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.schedule_rounded,
                              size: 13,
                              color: paid ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              paid ? 'Paid' : 'Due',
                              style: AppTypography.labelSmall.copyWith(
                                color: paid
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                if (flatWallet != null) ...[
                  const SizedBox(height: AppSizing.sm),
                  Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: AppSizing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Flat Pool  ',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '৳${flatWallet.balance.abs().toStringAsFixed(0)}',
                        style: AppTypography.titleMedium.copyWith(
                          color: flatWallet.isNegative
                              ? AppColors.error
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (flatWallet.isNegative) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(deficit)',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Pending request alert
                      if (summary.hasPendingRequests)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizing.radiusFull),
                          ),
                          child: Text(
                            '${summary.pendingPaymentRequests.length} request${summary.pendingPaymentRequests.length > 1 ? 's' : ''}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: AppSizing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Tap to open wallet →',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool accent;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizing.sm + 2),
        decoration: BoxDecoration(
          color: accent
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(
            color: accent
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: AppSizing.iconSm + 4,
              color: accent ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizing.xs),
            Text(
              value,
              style: AppTypography.titleLarge.copyWith(
                color: accent ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            Text(label, style: AppTypography.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppSizing.md),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: AppSizing.iconSm + 4,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSizing.xs),
                  Flexible(
                    child: Text(
                      label,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (badge != null && badge! > 0)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              ),
              child: Text(
                badge! > 99 ? '99+' : '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.headlineSmall),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
