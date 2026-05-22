import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/flat_wallet_entity.dart';
import '../../domain/entities/wallet_summary_entity.dart';
import '../args/submit_payment_args.dart';
import '../args/wallet_page_args.dart';
import '../bloc/wallet/wallet_bloc.dart';
import '../widgets/transaction_row.dart';

class WalletHomePage extends StatefulWidget {
  const WalletHomePage({super.key, required this.args});

  final WalletPageArgs args;

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(WalletSummaryRequested(widget.args.flatId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is WalletError) {
          AppSnackbar.error(context, state.message);
        }
        if (state is WalletPaymentSubmitSuccess) {
          AppSnackbar.success(context, AppStrings.paymentSubmittedMsg);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text(AppStrings.walletTitle,
                style: AppTypography.headlineMedium),
            actions: [
              if (widget.args.canManage)
                IconButton(
                  icon: const Icon(Icons.people_outline),
                  tooltip: AppStrings.allWalletsTitle,
                  onPressed: () => context.push(
                    AppRoutes.walletAllWallets,
                    extra: widget.args,
                  ),
                ),
              if (widget.args.canManage)
                IconButton(
                  icon: const Icon(Icons.receipt_long_outlined),
                  tooltip: AppStrings.paymentsListTitle,
                  onPressed: () => context.push(
                    AppRoutes.walletPayments,
                    extra: widget.args.flatId,
                  ),
                ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, WalletState state) {
    if (state is WalletLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final (summary, flatWallet) = switch (state) {
      WalletSummaryLoaded(summary: final s, flatWallet: final fw) => (s, fw),
      WalletActionLoading(summary: final s, flatWallet: final fw) => (s, fw),
      WalletPaymentSubmitSuccess(summary: final s, flatWallet: final fw) =>
        (s, fw),
      WalletError(summary: final s, flatWallet: final fw)
          when s != null =>
        (s, fw),
      _ => (null, null),
    };

    if (summary == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.somethingWentWrong,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSizing.md),
            AppButton(
              label: AppStrings.retry,
              onPressed: () => context
                  .read<WalletBloc>()
                  .add(WalletSummaryRequested(widget.args.flatId)),
              variant: AppButtonVariant.outlined,
            ),
          ],
        ),
      );
    }

    final isLoading = state is WalletActionLoading;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context
            .read<WalletBloc>()
            .add(WalletSummaryRequested(widget.args.flatId));
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero balance card ──────────────────────────
            _HeroBalanceCard(summary: summary),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizing.pagePadding,
                AppSizing.lg,
                AppSizing.pagePadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Flat Cash Pool ─────────────────────────
                  if (flatWallet != null) ...[
                    _FlatPoolCard(
                      flatWallet: flatWallet,
                      flatId: widget.args.flatId,
                    ),
                    const SizedBox(height: AppSizing.lg),
                  ],

                  // ── Contribution breakdown ─────────────────
                  _ContributionStrip(summary: summary),
                  const SizedBox(height: AppSizing.lg),

                  // ── Suggested deposit banner ───────────────
                  if (summary.suggestedTotalToPay > 0) ...[
                    _SuggestedDepositBanner(
                      summary: summary,
                      onPayNow: () => context.push(
                        AppRoutes.walletSubmitPayment,
                        extra: SubmitPaymentArgs(
                          flatId: widget.args.flatId,
                          initialAmount: summary.suggestedTotalToPay,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizing.lg),
                  ],

                  // ── Pending payment requests ───────────────
                  if (summary.hasPendingRequests) ...[
                    _SectionHeader(
                      title: AppStrings.paymentRequestsTitle,
                      badge: summary.pendingPaymentRequests.length,
                    ),
                    const SizedBox(height: AppSizing.sm),
                    ...summary.pendingPaymentRequests.map(
                      (req) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSizing.sm),
                        child: _RequestCard(
                          amount: req.amount,
                          note: req.note,
                          onPayNow: isLoading
                              ? null
                              : () => context.push(
                                    AppRoutes.walletSubmitPayment,
                                    extra: SubmitPaymentArgs(
                                      flatId: widget.args.flatId,
                                      paymentRequestId: req.id,
                                      requestedAmount: req.amount,
                                      requestNote: req.note,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizing.lg),
                  ],

                  // ── Recent activity ────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionHeader(title: AppStrings.recentActivity),
                      TextButton(
                        onPressed: () => context.push(
                          AppRoutes.walletTransactions,
                          extra: widget.args.flatId,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppStrings.seeAllTransactions,
                          style: AppTypography.titleMedium
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizing.sm),
                  if (summary.recentTransactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizing.md),
                      child: Center(
                        child: Text(
                          'No recent transactions.',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSizing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizing.md, vertical: AppSizing.xs),
                      child: Column(
                        children: summary.recentTransactions
                            .map((t) => TransactionRow(transaction: t))
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: AppSizing.xl),

                  // ── Actions ────────────────────────────────
                  AppButton(
                    label: AppStrings.submitPaymentLabel,
                    onPressed: isLoading
                        ? null
                        : () => context.push(
                              AppRoutes.walletSubmitPayment,
                              extra: SubmitPaymentArgs(
                                flatId: widget.args.flatId,
                                initialAmount:
                                    summary.suggestedTotalToPay > 0
                                        ? summary.suggestedTotalToPay
                                        : null,
                              ),
                            ),
                    variant: AppButtonVariant.primary,
                    fullWidth: true,
                    loading: isLoading,
                    icon: const Icon(Icons.send_rounded, size: 18),
                  ),

                  if (widget.args.canManage) ...[
                    const SizedBox(height: AppSizing.sm),
                    AppButton(
                      label: AppStrings.paymentRequestsTitle,
                      onPressed: () => context.push(
                        AppRoutes.walletRequests,
                        extra: widget.args,
                      ),
                      variant: AppButtonVariant.outlined,
                      fullWidth: true,
                      icon: const Icon(Icons.request_page_outlined, size: 18),
                    ),
                    const SizedBox(height: AppSizing.sm),
                    AppButton(
                      label: AppStrings.paymentHintsTitle,
                      onPressed: () => context.push(
                        AppRoutes.walletHints,
                        extra: widget.args.flatId,
                      ),
                      variant: AppButtonVariant.text,
                      fullWidth: true,
                    ),
                  ],

                  const SizedBox(height: AppSizing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero balance card ────────────────────────────────────────────────────────

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({required this.summary});
  final WalletSummaryEntity summary;

  @override
  Widget build(BuildContext context) {
    final isNeg = summary.isNegative;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSizing.pagePadding,
        AppSizing.lg,
        AppSizing.pagePadding,
        AppSizing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNeg
              ? [
                  AppColors.error,
                  AppColors.error.withValues(alpha: 0.7),
                ]
              : [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, ${summary.memberName}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSizing.xs),
          Text(
            '${isNeg ? '−' : ''}৳${summary.walletBalance.abs().toStringAsFixed(0)}',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.white,
              fontSize: 40,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizing.xs),
          Row(
            children: [
              Icon(
                isNeg
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: AppColors.white.withValues(alpha: 0.9),
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isNeg
                      ? 'You owe ৳${summary.walletBalance.abs().toStringAsFixed(0)} — please deposit soon'
                      : AppStrings.walletCurrentBalance,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          if (isNeg) ...[
            const SizedBox(height: AppSizing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
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
        ],
      ),
    );
  }
}

// ── Flat pool card ────────────────────────────────────────────────────────────

class _FlatPoolCard extends StatelessWidget {
  const _FlatPoolCard({required this.flatWallet, required this.flatId});
  final FlatWalletEntity flatWallet;
  final String flatId;

  @override
  Widget build(BuildContext context) {
    final isNeg = flatWallet.isNegative;
    final color = isNeg ? AppColors.error : AppColors.success;

    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.walletTransactions, extra: flatId),
      child: Container(
        padding: const EdgeInsets.all(AppSizing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizing.radiusSm),
              ),
              child: Icon(Icons.account_balance_rounded, color: color, size: 22),
            ),
            const SizedBox(width: AppSizing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.flatWalletTitle,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${isNeg ? '−' : ''}৳${flatWallet.balance.abs().toStringAsFixed(0)}',
                        style: AppTypography.titleLarge.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isNeg) ...[
                        const SizedBox(width: AppSizing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizing.radiusFull),
                          ),
                          child: Text(
                            'Deficit',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Contribution strip ────────────────────────────────────────────────────────

class _ContributionStrip extends StatelessWidget {
  const _ContributionStrip({required this.summary});
  final WalletSummaryEntity summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StripItem(
            label: 'Fixed',
            value: '৳${summary.fixedContribution.toStringAsFixed(0)}',
            icon: Icons.receipt_long_outlined,
          ),
          _VerticalDivider(),
          _StripItem(
            label: 'Meal',
            value:
                '৳${summary.paymentHints.suggestedMealAmount.toStringAsFixed(0)}',
            icon: Icons.restaurant_outlined,
          ),
          _VerticalDivider(),
          _StripItem(
            label: 'Household',
            value:
                '৳${summary.paymentHints.suggestedHouseholdAmount.toStringAsFixed(0)}',
            icon: Icons.home_outlined,
          ),
        ],
      ),
    );
  }
}

class _StripItem extends StatelessWidget {
  const _StripItem(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(value,
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: AppColors.border,
    );
  }
}

// ── Suggested deposit banner ──────────────────────────────────────────────────

class _SuggestedDepositBanner extends StatelessWidget {
  const _SuggestedDepositBanner(
      {required this.summary, required this.onPayNow});
  final WalletSummaryEntity summary;
  final VoidCallback onPayNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.suggestedDeposit,
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  '৳${summary.suggestedTotalToPay.toStringAsFixed(0)}',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fixed ৳${summary.fixedContribution.toStringAsFixed(0)} + Meal ৳${summary.paymentHints.suggestedMealAmount.toStringAsFixed(0)} + Household ৳${summary.paymentHints.suggestedHouseholdAmount.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizing.sm),
          AppButton(
            label: AppStrings.payNow,
            onPressed: onPayNow,
            variant: AppButtonVariant.primary,
            height: AppSizing.buttonHeightSm,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.badge});
  final String title;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTypography.headlineSmall),
        if (badge != null && badge! > 0) ...[
          const SizedBox(width: AppSizing.xs),
          Container(
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppSizing.radiusFull),
            ),
            child: Text(
              '$badge',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.amount, this.note, this.onPayNow});
  final double amount;
  final String? note;
  final VoidCallback? onPayNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '৳${amount.toStringAsFixed(0)}',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (note != null && note!.isNotEmpty)
                  Text(
                    note!,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSizing.sm),
          AppButton(
            label: AppStrings.payNow,
            onPressed: onPayNow,
            variant: AppButtonVariant.primary,
            height: AppSizing.buttonHeightSm,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
