import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../bloc/payments/payments_bloc.dart';
import '../bloc/wallet/wallet_bloc.dart';
import '../widgets/payment_card.dart';

class PaymentsListPage extends StatefulWidget {
  const PaymentsListPage({super.key, required this.flatId});

  final String flatId;

  @override
  State<PaymentsListPage> createState() => _PaymentsListPageState();
}

class _PaymentsListPageState extends State<PaymentsListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTab('pending');
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final status = switch (_tabController.index) {
          0 => 'pending',
          1 => 'verified',
          _ => 'rejected',
        };
        context.read<PaymentsBloc>().add(
              PaymentsLoadRequested(widget.flatId, status: status),
            );
      }
    });
  }

  void _loadTab(String status) {
    context.read<PaymentsBloc>().add(
          PaymentsLoadRequested(widget.flatId, status: status),
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentsBloc, PaymentsState>(
      listener: (context, state) {
        if (state is PaymentsActionError) {
          AppSnackbar.error(context, state.message);
        }
        if (state is PaymentVerifySuccess) {
          _showVerifyResultDialog(context, state);
          context
              .read<WalletBloc>()
              .add(WalletSummaryRequested(widget.flatId));
        }
        if (state is PaymentRejectSuccess) {
          AppSnackbar.success(context, AppStrings.paymentRejectedMsg);
          context
              .read<WalletBloc>()
              .add(WalletSummaryRequested(widget.flatId));
        }
      },
      builder: (context, state) {
        int pendingBadge = 0;
        if (state is PaymentsLoaded && state.statusFilter == 'pending') {
          pendingBadge = state.payments.length;
        }

        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            backgroundColor: context.bgColor,
            elevation: 0,
            title: Text(AppStrings.paymentsListTitle,
                style: AppTypography.headlineMedium),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: context.textSecColor,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pending'),
                      if (pendingBadge > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          constraints:
                              const BoxConstraints(minWidth: 18, minHeight: 18),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius:
                                BorderRadius.circular(AppSizing.radiusFull),
                          ),
                          child: Text(
                            '$pendingBadge',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Verified'),
                const Tab(text: 'Rejected'),
              ],
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PaymentsState state) {
    final payments = switch (state) {
      PaymentsLoaded(payments: final p) => p,
      PaymentsActionLoading(payments: final p) => p,
      PaymentVerifySuccess(payments: final p) => p,
      PaymentRejectSuccess(payments: final p) => p,
      PaymentsActionError(payments: final p) => p,
      _ => null,
    };

    if (state is PaymentsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state is PaymentsError) {
      return Center(
        child: Text(state.message,
            style: AppTypography.bodyMedium
                .copyWith(color: context.textSecColor)),
      );
    }
    if (payments == null || payments.isEmpty) {
      return Center(
        child: Text(
          'No payments here.',
          style: AppTypography.bodyMedium
              .copyWith(color: context.textSecColor),
        ),
      );
    }

    final isActionLoading = state is PaymentsActionLoading;
    final isPendingTab = _tabController.index == 0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        final status = switch (_tabController.index) {
          0 => 'pending',
          1 => 'verified',
          _ => 'rejected',
        };
        context.read<PaymentsBloc>().add(
              PaymentsLoadRequested(widget.flatId, status: status),
            );
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizing.pagePadding),
        itemCount: payments.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSizing.md),
        itemBuilder: (context, index) {
          final payment = payments[index];
          return PaymentCard(
            payment: payment,
            onVerify: isPendingTab && !isActionLoading
                ? () => _confirmVerify(context, payment.id,
                    payment.fromMemberName ?? '—', payment.amount,
                    payment.paymentMethod)
                : null,
            onReject: isPendingTab && !isActionLoading
                ? () => _showRejectSheet(context, payment.id)
                : null,
          );
        },
      ),
    );
  }

  void _confirmVerify(BuildContext context, String paymentId, String memberName,
      double amount, String method) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.verifyConfirmTitle),
        content: Text(
            'Confirm ৳${amount.toStringAsFixed(0)} from $memberName via ${method.toUpperCase()}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PaymentsBloc>().add(PaymentVerifyRequested(
                    flatId: widget.flatId,
                    paymentId: paymentId,
                  ));
            },
            child: Text(AppStrings.verifyPaymentLabel,
                style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  void _showRejectSheet(BuildContext context, String paymentId) {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizing.radiusLg)),
      ),
      builder: (_) => Padding(
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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSizing.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              ),
            ),
            Text(AppStrings.rejectPaymentLabel,
                style: AppTypography.headlineSmall),
            const SizedBox(height: AppSizing.md),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppStrings.rejectReasonLabel,
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizing.radiusMd)),
              ),
            ),
            const SizedBox(height: AppSizing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<PaymentsBloc>().add(PaymentRejectRequested(
                        flatId: widget.flatId,
                        paymentId: paymentId,
                        reason: reasonController.text.trim().isEmpty
                            ? null
                            : reasonController.text.trim(),
                      ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                ),
                child: Text(AppStrings.rejectPaymentLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerifyResultDialog(
      BuildContext context, PaymentVerifySuccess state) {
    final r = state.result;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Payment Verified'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${r.memberName}'s balance: ৳${r.oldBalance.toStringAsFixed(0)} → ৳${r.newBalance.toStringAsFixed(0)}",
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSizing.xs),
            Text(
              'Flat wallet: ৳${r.flatWalletOld.toStringAsFixed(0)} → ৳${r.flatWalletNew.toStringAsFixed(0)}',
              style: AppTypography.bodyMedium,
            ),
            if (r.autoDeducted) ...[
              const SizedBox(height: AppSizing.sm),
              Container(
                padding: const EdgeInsets.all(AppSizing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                ),
                child: Text(
                  'Fixed contribution of ৳${r.deductedAmount.toStringAsFixed(0)} was automatically deducted. ${r.memberName}\'s net balance: ৳${r.newBalance.toStringAsFixed(0)}.',
                  style: AppTypography.bodySmall
                      .copyWith(color: const Color(0xFF0D9488)),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<PaymentsBloc>()
                  .add(const PaymentVerifyResultAcknowledged());
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
