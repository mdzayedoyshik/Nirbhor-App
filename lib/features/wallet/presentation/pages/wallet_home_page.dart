import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../flat/presentation/bloc/flat_bloc.dart';
import '../../domain/entities/flat_wallet_entity.dart';
import '../../domain/entities/wallet_summary_entity.dart';
import '../args/submit_payment_args.dart';
import '../args/transaction_history_args.dart';
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

  /// Builds the args for the Transaction History page by reading flat + auth
  /// context from the singleton BLoCs.
  TransactionHistoryArgs _buildTxHistoryArgs() {
    final flatState = sl<FlatBloc>().state;
    final flat = switch (flatState) {
      FlatLoaded(:final flat) => flat,
      FlatPendingExit(:final flat) => flat,
      _ => null,
    };
    final authState = sl<AuthBloc>().state;
    final userId =
        authState is AuthAuthenticated ? authState.user.id : '';
    final member = flat?.memberByUserId(userId);
    return TransactionHistoryArgs(
      flatId: widget.args.flatId,
      myMemberId: member?.flatMemberId ?? '',
      members: flat?.activeMembers ?? const [],
    );
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
            // ── Balance section ────────────────────────────
            _BalanceSection(summary: summary, flatWallet: flatWallet),

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
                  // _QuickActionsRow(
                  //   flatId: widget.args.flatId,
                  //   args: widget.args,
                  //   summary: summary,
                  //   isLoading: isLoading,
                  // ),
                  // const SizedBox(height: AppSizing.lg),

                  // ── Suggested deposit banner ───────────────
                  if (summary.suggestedTotalToPay > 0) ...[
                    _SuggestedDepositBanner(
                      summary: summary,
                      onPayNow: () => context.push(
                        AppRoutes.walletSubmitPayment,
                        extra: SubmitPaymentArgs(
                          flatId: widget.args.flatId,
                          canManage: widget.args.canManage,
                          initialAmount: summary.suggestedTotalToPay,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizing.lg),
                  ],

                  // ── Pending / awaiting payment requests ───────────────
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
                          isSubmitted: req.isSubmitted,
                          onPayNow: req.isSubmitted || isLoading
                              ? null
                              : () => context.push(
                                    AppRoutes.walletSubmitPayment,
                                    extra: SubmitPaymentArgs(
                                      flatId: widget.args.flatId,
                                      canManage: widget.args.canManage,
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
                          extra: _buildTxHistoryArgs(),
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

// ── Balance section ───────────────────────────────────────────────────────────

class _BalanceSection extends StatelessWidget {
  const _BalanceSection({required this.summary, required this.flatWallet});
  final WalletSummaryEntity summary;
  final FlatWalletEntity? flatWallet;

  @override
  Widget build(BuildContext context) {
    final isNeg = summary.isNegative;
    final statusColor = isNeg ? AppColors.error : AppColors.success;
    final amountColor = isNeg ? AppColors.error : context.textPrimColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizing.pagePadding,
        AppSizing.xs,
        AppSizing.pagePadding,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.md + 2, vertical: AppSizing.md),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppSizing.r16),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // My balance
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.walletCurrentBalance,
                    style: AppTypography.labelS
                        .copyWith(color: context.textSecColor),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${isNeg ? '−' : ''}৳${summary.walletBalance.abs().toStringAsFixed(0)}',
                        style: AppTypography.amountXL.copyWith(
                          color: amountColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: AppSizing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusFull),
                        ),
                        child: Text(
                          isNeg ? 'Due' : 'Healthy',
                          style: AppTypography.labelS.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Divider + pool balance
            if (flatWallet != null) ...[
              Container(
                width: 1,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: AppSizing.md),
                color: context.borderColor,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Flat Pool',
                    style: AppTypography.labelS
                        .copyWith(color: context.textSecColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${flatWallet!.isNegative ? '−' : ''}৳${flatWallet!.balance.abs().toStringAsFixed(0)}',
                    style: AppTypography.amountM.copyWith(
                      color: flatWallet!.isNegative
                          ? AppColors.error
                          : context.textPrimColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Quick actions row ────────────────────────────────────────────────────────

// class _QuickActionsRow extends StatelessWidget {
//   const _QuickActionsRow({
//     required this.flatId,
//     required this.args,
//     required this.summary,
//     required this.isLoading,
//   });
//   final String flatId;
//   final WalletPageArgs args;
//   final WalletSummaryEntity summary;
//   final bool isLoading;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         _QuickActionButton(
//           icon: Icons.send_rounded,
//           label: 'Pay',
//           isPrimary: true,
//           onTap: isLoading
//               ? null
//               : () => context.push(
//                     AppRoutes.walletSubmitPayment,
//                     extra: SubmitPaymentArgs(
//                       flatId: flatId,
//                       initialAmount: summary.suggestedTotalToPay > 0
//                           ? summary.suggestedTotalToPay
//                           : null,
//                     ),
//                   ),
//         ),
//         const SizedBox(width: AppSizing.sm),
//         _QuickActionButton(
//           icon: Icons.payments_outlined,
//           label: 'Payments',
//           onTap: () => context.push(
//             AppRoutes.walletRequests,
//             extra: args,
//           ),
//         ),
//         const SizedBox(width: AppSizing.sm),
//         _QuickActionButton(
//           icon: Icons.history_rounded,
//           label: 'History',
//           onTap: () => context.push(
//             AppRoutes.walletTransactions,
//             extra: flatId,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _QuickActionButton extends StatelessWidget {
//   const _QuickActionButton({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//     this.isPrimary = false,
//   });
//   final IconData icon;
//   final String label;
//   final VoidCallback? onTap;
//   final bool isPrimary;

//   @override
//   Widget build(BuildContext context) {
//     final enabled = onTap != null;
//     final accent = isPrimary && enabled ? AppColors.brand : null;

//     return Expanded(
//       child: GestureDetector(
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 10),
//           decoration: BoxDecoration(
//             color: accent != null
//                 ? AppColors.brand.withValues(alpha: 0.07)
//                 : context.cardColor,
//             borderRadius: BorderRadius.circular(AppSizing.r12),
//             border: Border.all(
//               color: accent != null
//                   ? AppColors.brand.withValues(alpha: 0.35)
//                   : AppColors.border,
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 icon,
//                 size: 18,
//                 color: enabled
//                     ? (accent ?? AppColors.brand)
//                     : AppColors.textHint,
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 label,
//                 style: AppTypography.labelS.copyWith(
//                   color: enabled
//                       ? (accent != null
//                           ? AppColors.brand
//                           : context.textPrimColor)
//                       : AppColors.textHint,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


// ── Suggested deposit banner ──────────────────────────────────────────────────

class _SuggestedDepositBanner extends StatelessWidget {
  const _SuggestedDepositBanner(
      {required this.summary, required this.onPayNow});
  final WalletSummaryEntity summary;
  final VoidCallback onPayNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.md, vertical: AppSizing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizing.r12),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.suggestedDeposit,
                  style: AppTypography.labelS
                      .copyWith(color: context.textSecColor),
                ),
                Text(
                  '৳${summary.suggestedTotalToPay.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Fixed ${summary.fixedContribution.toStringAsFixed(0)} + Meal ${summary.paymentHints.suggestedMealAmount.toStringAsFixed(0)} + HH ${summary.paymentHints.suggestedHouseholdAmount.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
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
  const _RequestCard({
    required this.amount,
    this.note,
    this.onPayNow,
    this.isSubmitted = false,
  });
  final double amount;
  final String? note;
  final VoidCallback? onPayNow;
  final bool isSubmitted;

  @override
  Widget build(BuildContext context) {
    final accent = isSubmitted ? AppColors.success : AppColors.brand;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.md, vertical: AppSizing.sm + 2),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.r12),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isSubmitted ? Icons.hourglass_top_rounded : Icons.request_page_outlined,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: AppSizing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '৳${amount.toStringAsFixed(0)}',
                  style: AppTypography.amountM.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isSubmitted ? 'Awaiting verification' : (note ?? 'Payment request'),
                  style: AppTypography.bodySmall
                      .copyWith(color: context.textSecColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizing.sm),
          if (isSubmitted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Paid',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            )
          else
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
        border: Border.all(color: context.borderColor),
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
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.r16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined,
                color: AppColors.brand, size: 26),
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
