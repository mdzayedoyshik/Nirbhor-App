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
          appBar: AppBar(
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
                  icon: const Icon(Icons.payment_rounded),
                  tooltip: 'Manage Payments',
                  onPressed: () => context.push(
                    AppRoutes.walletRequests,
                    extra: widget.args,
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
          child: CircularProgressIndicator(color: AppColors.brand));
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
                    .copyWith(color: context.textSecColor)),
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
      color: AppColors.brand,
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
            // ── Compact balance card ───────────────────────
            _BalanceCard(summary: summary, flatWallet: flatWallet),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizing.pagePadding,
                AppSizing.md,
                AppSizing.pagePadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick actions ──────────────────────────
                  _QuickActionsRow(
                    flatId: widget.args.flatId,
                    args: widget.args,
                    summary: summary,
                    isLoading: isLoading,
                  ),
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
                          foregroundColor: AppColors.brand,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppStrings.seeAllTransactions,
                          style: AppTypography.titleMedium
                              .copyWith(color: AppColors.brand),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizing.sm),
                  if (summary.recentTransactions.isEmpty)
                    _EmptyTransactionsState()
                  else
                    _TransactionsList(
                        transactions: summary.recentTransactions),

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

// ── Compact balance card ─────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary, required this.flatWallet});
  final WalletSummaryEntity summary;
  final FlatWalletEntity? flatWallet;

  @override
  Widget build(BuildContext context) {
    final isNeg = summary.isNegative;
    final gradient = isNeg ? AppColors.warmGradient : AppColors.brandGradient;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSizing.pagePadding,
        AppSizing.sm,
        AppSizing.pagePadding,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.lg,
        vertical: AppSizing.md,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSizing.r24),
        boxShadow: AppColors.shadowLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.walletCurrentBalance,
                      style: AppTypography.labelS.copyWith(
                        color: AppColors.white.withValues(alpha: 0.75),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isNeg ? '−' : ''}৳${summary.walletBalance.abs().toStringAsFixed(0)}',
                      style: AppTypography.amountXL.copyWith(
                        color: AppColors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isNeg
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline_rounded,
                      color: AppColors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isNeg ? 'Due' : 'Healthy',
                      style: AppTypography.labelS.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (flatWallet != null) ...[
            const SizedBox(height: AppSizing.sm),
            Container(
              height: 1,
              color: AppColors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: AppSizing.sm),
            Row(
              children: [
                Icon(Icons.account_balance_rounded,
                    size: 13, color: AppColors.white.withValues(alpha: 0.75)),
                const SizedBox(width: 5),
                Text(
                  'Pool: ${flatWallet!.isNegative ? '−' : ''}৳${flatWallet!.balance.abs().toStringAsFixed(0)}',
                  style: AppTypography.labelS.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Quick actions row ────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.flatId,
    required this.args,
    required this.summary,
    required this.isLoading,
  });
  final String flatId;
  final WalletPageArgs args;
  final WalletSummaryEntity summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickActionButton(
          icon: Icons.send_rounded,
          label: 'Pay',
          onTap: isLoading
              ? null
              : () => context.push(
                    AppRoutes.walletSubmitPayment,
                    extra: SubmitPaymentArgs(
                      flatId: flatId,
                      initialAmount: summary.suggestedTotalToPay > 0
                          ? summary.suggestedTotalToPay
                          : null,
                    ),
                  ),
        ),
        const SizedBox(width: AppSizing.sm),
        _QuickActionButton(
          icon: Icons.request_page_outlined,
          label: 'Request',
          onTap: () => context.push(
            AppRoutes.walletRequests,
            extra: args,
          ),
        ),
        const SizedBox(width: AppSizing.sm),
        _QuickActionButton(
          icon: Icons.history_rounded,
          label: 'History',
          onTap: () => context.push(
            AppRoutes.walletTransactions,
            extra: flatId,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: AppSizing.md, horizontal: AppSizing.sm),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(AppSizing.r16),
            boxShadow: AppColors.shadowSm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                ),
                child: Icon(icon, color: AppColors.white, size: 20),
              ),
              const SizedBox(height: AppSizing.xs),
              Text(
                label,
                style: AppTypography.labelM.copyWith(
                  color: context.textPrimColor,
                ),
              ),
            ],
          ),
        ),
      ),
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
        color: AppColors.brand.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizing.r16),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppSizing.r12),
            ),
            child: const Icon(Icons.savings_outlined,
                color: AppColors.white, size: 22),
          ),
          const SizedBox(width: AppSizing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.suggestedDeposit,
                  style: AppTypography.labelS
                      .copyWith(color: context.textSecColor),
                ),
                const SizedBox(height: 2),
                Text(
                  '৳${summary.suggestedTotalToPay.toStringAsFixed(0)}',
                  style: AppTypography.amountM.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fixed ৳${summary.fixedContribution.toStringAsFixed(0)} + Meal ৳${summary.paymentHints.suggestedMealAmount.toStringAsFixed(0)} + Household ৳${summary.paymentHints.suggestedHouseholdAmount.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall
                      .copyWith(color: context.textSecColor),
                  maxLines: 1,
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
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.r16),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.25)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppSizing.r12),
            ),
            child: const Icon(Icons.request_page_outlined,
                color: AppColors.white, size: 20),
          ),
          const SizedBox(width: AppSizing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '৳${amount.toStringAsFixed(0)}',
                  style: AppTypography.amountL.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (note != null && note!.isNotEmpty)
                  Text(
                    note!,
                    style: AppTypography.bodySmall
                        .copyWith(color: context.textSecColor),
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

// ── Transactions list ─────────────────────────────────────────────────────────

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({required this.transactions});
  final List<dynamic> transactions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.r16),
        boxShadow: AppColors.shadowSm,
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.md, vertical: AppSizing.xs),
      child: Column(
        children:
            transactions.map((t) => TransactionRow(transaction: t)).toList(),
      ),
    );
  }
}

// ── Empty transactions state ──────────────────────────────────────────────────

class _EmptyTransactionsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSizing.xl, horizontal: AppSizing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface100,
        borderRadius: BorderRadius.circular(AppSizing.r16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: AppColors.white, size: 30),
          ),
          const SizedBox(height: AppSizing.md),
          Text(
            'No transactions yet',
            style: AppTypography.h4.copyWith(color: context.textPrimColor),
          ),
          const SizedBox(height: AppSizing.xs),
          Text(
            'Your recent payments will appear here.',
            style: AppTypography.bodyS
                .copyWith(color: context.textSecColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
