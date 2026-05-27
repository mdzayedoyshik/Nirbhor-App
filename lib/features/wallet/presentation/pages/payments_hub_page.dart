import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/services/push_notification_service.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../flat/domain/entities/flat_member_entity.dart';
import '../../../flat/presentation/bloc/flat_bloc.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/payment_request_entity.dart';
import '../args/submit_payment_args.dart';
import '../args/wallet_page_args.dart';
import '../bloc/payment_requests/payment_requests_bloc.dart';
import '../bloc/payments/payments_bloc.dart';
import '../bloc/wallet/wallet_bloc.dart';
import '../widgets/payment_card.dart';
import '../widgets/payment_request_card.dart';

class PaymentsHubPage extends StatefulWidget {
  const PaymentsHubPage({super.key, required this.args});

  final WalletPageArgs args;

  @override
  State<PaymentsHubPage> createState() => _PaymentsHubPageState();
}

class _PaymentsHubPageState extends State<PaymentsHubPage> {
  int _selectedTab = 0;
  StreamSubscription<ForegroundPushEvent>? _pushSub;

  static const List<String> _tabLabels = [
    'Pending',
    'Awaiting',
    'Verified',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
    // Reload when a payment-related push arrives in the foreground
    _pushSub = PushNotificationService.instance.foregroundStream.listen((event) {
      if (event.isPayment && mounted) _loadAll();
    });
  }

  @override
  void dispose() {
    _pushSub?.cancel();
    super.dispose();
  }

  void _loadAll() {
    context.read<PaymentRequestsBloc>().add(
          PaymentRequestsLoadRequested(widget.args.flatId, status: 'pending'),
        );
    context.read<PaymentsBloc>().add(
          PaymentsLoadRequested(widget.args.flatId, status: 'pending'),
        );
  }

  void _onTabChanged(int index) {
    setState(() => _selectedTab = index);
    switch (index) {
      case 0:
        context.read<PaymentRequestsBloc>().add(
              PaymentRequestsLoadRequested(widget.args.flatId, status: 'pending'),
            );
      case 1:
        context.read<PaymentsBloc>().add(
              PaymentsLoadRequested(widget.args.flatId, status: 'pending'),
            );
      case 2:
        context.read<PaymentsBloc>().add(
              PaymentsLoadRequested(widget.args.flatId, status: 'verified'),
            );
      case 3:
        // Tab 3 loads both rejected payments and cancelled requests
        context.read<PaymentsBloc>().add(
              PaymentsLoadRequested(widget.args.flatId, status: 'rejected'),
            );
        context.read<PaymentRequestsBloc>().add(
              PaymentRequestsLoadRequested(widget.args.flatId, status: 'cancelled'),
            );
    }
  }

  Future<void> _onRefresh() async {
    context.read<PaymentRequestsBloc>().add(
          PaymentRequestsLoadRequested(
            widget.args.flatId,
            status: _selectedTab == 0
                ? 'pending'
                : _selectedTab == 3
                    ? 'cancelled'
                    : null,
          ),
        );
    context.read<PaymentsBloc>().add(
          PaymentsLoadRequested(
            widget.args.flatId,
            status: switch (_selectedTab) {
              1 => 'pending',
              2 => 'verified',
              3 => 'rejected',
              _ => null,
            },
          ),
        );
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PaymentRequestsBloc, PaymentRequestsState>(
          listener: (context, state) {
            if (state is PaymentRequestsActionError) {
              AppSnackbar.error(context, state.message);
            }
            if (state is PaymentRequestCreateSuccess) {
              AppSnackbar.success(context, AppStrings.paymentRequestSentMsg);
              context.read<WalletBloc>().add(WalletSummaryRequested(widget.args.flatId));
            }
            if (state is PaymentRequestBulkCreateSuccess) {
              final msg = state.skippedCount > 0
                  ? '${state.sentCount} sent, ${state.skippedCount} skipped (duplicate or error).'
                  : '${state.sentCount} request${state.sentCount == 1 ? '' : 's'} sent.';
              AppSnackbar.success(context, msg);
              context.read<WalletBloc>().add(WalletSummaryRequested(widget.args.flatId));
            }
            if (state is PaymentRequestCancelSuccess) {
              AppSnackbar.success(context, AppStrings.paymentRequestCancelledMsg);
              context.read<WalletBloc>().add(WalletSummaryRequested(widget.args.flatId));
            }
          },
        ),
        BlocListener<PaymentsBloc, PaymentsState>(
          listener: (context, state) {
            if (state is PaymentsActionError) {
              AppSnackbar.error(context, state.message);
            }
            if (state is PaymentVerifySuccess) {
              _showVerifyResultDialog(context, state);
              context.read<WalletBloc>().add(WalletSummaryRequested(widget.args.flatId));
            }
            if (state is PaymentRejectSuccess) {
              AppSnackbar.success(context, AppStrings.paymentRejectedMsg);
              context.read<WalletBloc>().add(WalletSummaryRequested(widget.args.flatId));
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text('Manage Payments', style: AppTypography.headlineMedium),
        ),
        floatingActionButton: widget.args.canManage
            ? FloatingActionButton.extended(
                onPressed: () => _showCreateRequestSheet(context),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add, color: AppColors.white),
                label: Text(
                  'New Request',
                  style: AppTypography.labelLarge.copyWith(color: AppColors.white),
                ),
              )
            : null,
        body: Column(
          children: [
            // ── Pill Tab Bar ──────────────────────────────────────────────────
            _PillTabBar(
              selectedIndex: _selectedTab,
              labels: _tabLabels,
              onChanged: _onTabChanged,
            ),
            const SizedBox(height: AppSizing.sm),
            // ── Tab Content ───────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _onRefresh,
                child: _buildTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _PendingRequestsTab(args: widget.args);
      case 1:
        return _AwaitingVerificationTab(args: widget.args);
      case 2:
        return _VerifiedTab(args: widget.args);
      case 3:
        return _RejectedTab(args: widget.args);
      default:
        return const SizedBox.shrink();
    }
  }

  void _showVerifyResultDialog(BuildContext context, PaymentVerifySuccess state) {
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
              context.read<PaymentsBloc>().add(const PaymentVerifyResultAcknowledged());
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCreateRequestSheet(BuildContext context) {
    final flat = (context.read<FlatBloc>().state is FlatLoaded)
        ? (context.read<FlatBloc>().state as FlatLoaded).flat
        : null;
    final members = flat?.activeMembers ?? <FlatMemberEntity>[];

    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final selectedIds = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizing.radiusLg)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final bool canSubmit = selectedIds.isNotEmpty;
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            builder: (_, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizing.pagePadding, AppSizing.md, AppSizing.pagePadding, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Text(AppStrings.newPaymentRequestTitle,
                          style: AppTypography.headlineSmall),
                      const SizedBox(height: AppSizing.xs),
                      Text('Select one or more members',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      AppSizing.pagePadding,
                      AppSizing.sm,
                      AppSizing.pagePadding,
                      MediaQuery.of(context).viewInsets.bottom + AppSizing.pagePadding,
                    ),
                    children: [
                      ...members.map((m) {
                        final checked = selectedIds.contains(m.flatMemberId);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (v) => setSheetState(() {
                            if (v == true) {
                              selectedIds.add(m.flatMemberId);
                            } else {
                              selectedIds.remove(m.flatMemberId);
                            }
                          }),
                          title: Text(m.name, style: AppTypography.bodyMedium),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }),
                      const SizedBox(height: AppSizing.md),
                      AppTextField(
                        controller: amountController,
                        label: AppStrings.paymentAmountLabel,
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppSizing.md),
                      AppTextField(
                        controller: noteController,
                        label: AppStrings.requestPurposeLabel,
                        hint: 'e.g. January contribution',
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSizing.lg),
                      AppButton(
                        label: canSubmit
                            ? 'Send to ${selectedIds.length} member${selectedIds.length == 1 ? '' : 's'}'
                            : AppStrings.sendRequestLabel,
                        onPressed: canSubmit
                            ? () {
                                final amount =
                                    double.tryParse(amountController.text.trim()) ?? 0;
                                if (amount <= 0) return;
                                Navigator.pop(sheetCtx);
                                context.read<PaymentRequestsBloc>().add(
                                      PaymentRequestBulkCreateRequested(
                                        flatId: widget.args.flatId,
                                        memberIds: selectedIds.toList(),
                                        amount: amount,
                                        note: noteController.text.trim().isEmpty
                                            ? null
                                            : noteController.text.trim(),
                                      ),
                                    );
                              }
                            : null,
                        variant: AppButtonVariant.primary,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Pill Tab Bar ──────────────────────────────────────────────────────────────

class _PillTabBar extends StatelessWidget {
  const _PillTabBar({
    required this.selectedIndex,
    required this.labels,
    required this.onChanged,
  });

  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSizing.pagePadding, AppSizing.md, AppSizing.pagePadding, 0),
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface200,
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.transparent,
                  borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                ),
                alignment: Alignment.center,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTypography.labelSmall.copyWith(
                    color: selected
                        ? AppColors.white
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  child: Text(labels[i]),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Tab 0: Pending Payment Requests ──────────────────────────────────────────

class _PendingRequestsTab extends StatelessWidget {
  const _PendingRequestsTab({required this.args});
  final WalletPageArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentRequestsBloc, PaymentRequestsState>(
      builder: (context, state) {
        if (state is PaymentRequestsLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is PaymentRequestsError) {
          return _ErrorState(message: state.message);
        }

        final requests = switch (state) {
          PaymentRequestsLoaded(requests: final r) => r,
          PaymentRequestsActionLoading(requests: final r) => r,
          PaymentRequestCreateSuccess(requests: final r) => r,
          PaymentRequestCancelSuccess(requests: final r) => r,
          PaymentRequestsActionError(requests: final r) => r,
          _ => null,
        };

        if (requests == null || requests.isEmpty) {
          return const _EmptyState(
            icon: Icons.hourglass_empty_rounded,
            message: 'No pending payment requests',
          );
        }

        final isActionLoading = state is PaymentRequestsActionLoading;

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
              AppSizing.pagePadding,
              AppSizing.sm,
              AppSizing.pagePadding,
              AppSizing.pagePadding + 72),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSizing.md),
          itemBuilder: (context, index) {
            final req = requests[index];
            return PaymentRequestCard(
              request: req,
              showMemberName: args.canManage,
              onPayNow: !args.canManage && !isActionLoading
                  ? () => context.push(
                        AppRoutes.walletSubmitPayment,
                        extra: SubmitPaymentArgs(
                          flatId: args.flatId,
                          paymentRequestId: req.id,
                          requestedAmount: req.amount,
                          requestNote: req.note,
                          requestedByName: req.requestedByName,
                        ),
                      )
                  : null,
              onCancel: args.canManage && !isActionLoading
                  ? () => _confirmCancel(context, req, args.flatId)
                  : null,
            );
          },
        );
      },
    );
  }

  void _confirmCancel(
      BuildContext context, PaymentRequestEntity req, String flatId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: Text(AppStrings.cancelRequestMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PaymentRequestsBloc>().add(
                    PaymentRequestCancelRequested(
                      flatId: flatId,
                      requestId: req.id,
                    ),
                  );
            },
            child: Text(AppStrings.cancel,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Awaiting Verification (submitted payments) ────────────────────────

class _AwaitingVerificationTab extends StatelessWidget {
  const _AwaitingVerificationTab({required this.args});
  final WalletPageArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentsBloc, PaymentsState>(
      builder: (context, state) {
        if (state is PaymentsLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is PaymentsError) {
          return _ErrorState(message: state.message);
        }

        final payments = _extractPayments(state);

        if (payments == null || payments.isEmpty) {
          return const _EmptyState(
            icon: Icons.pending_actions_rounded,
            message: 'No payments awaiting verification',
          );
        }

        final isActionLoading = state is PaymentsActionLoading;

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
              AppSizing.pagePadding,
              AppSizing.sm,
              AppSizing.pagePadding,
              AppSizing.pagePadding + 72),
          itemCount: payments.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSizing.md),
          itemBuilder: (context, index) {
            final payment = payments[index];
            return PaymentCard(
              payment: payment,
              onVerify: args.canManage && !isActionLoading
                  ? () => _confirmVerify(context, payment, args.flatId)
                  : null,
              onReject: args.canManage && !isActionLoading
                  ? () => _showRejectSheet(context, payment.id, args.flatId)
                  : null,
            );
          },
        );
      },
    );
  }

  List<PaymentEntity>? _extractPayments(PaymentsState state) => switch (state) {
        PaymentsLoaded(payments: final p) => p,
        PaymentsActionLoading(payments: final p) => p,
        PaymentVerifySuccess(payments: final p) => p,
        PaymentRejectSuccess(payments: final p) => p,
        PaymentsActionError(payments: final p) => p,
        _ => null,
      };

  void _confirmVerify(
      BuildContext context, PaymentEntity payment, String flatId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.verifyConfirmTitle),
        content: Text(
            'Confirm ৳${payment.amount.toStringAsFixed(0)} from ${payment.fromMemberName ?? '—'} via ${payment.paymentMethod.toUpperCase()}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PaymentsBloc>().add(PaymentVerifyRequested(
                    flatId: flatId,
                    paymentId: payment.id,
                  ));
            },
            child: Text(AppStrings.verifyPaymentLabel,
                style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  void _showRejectSheet(
      BuildContext context, String paymentId, String flatId) {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizing.radiusLg)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSizing.pagePadding,
          AppSizing.md,
          AppSizing.pagePadding,
          MediaQuery.of(sheetCtx).viewInsets.bottom + AppSizing.pagePadding,
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
                color: AppColors.border,
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
                    borderRadius: BorderRadius.circular(AppSizing.radiusMd)),
              ),
            ),
            const SizedBox(height: AppSizing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  context.read<PaymentsBloc>().add(PaymentRejectRequested(
                        flatId: flatId,
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
}

// ── Tab 2: Verified ───────────────────────────────────────────────────────────

class _VerifiedTab extends StatelessWidget {
  const _VerifiedTab({required this.args});
  final WalletPageArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentsBloc, PaymentsState>(
      builder: (context, state) {
        if (state is PaymentsLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is PaymentsError) {
          return _ErrorState(message: state.message);
        }

        final payments = switch (state) {
          PaymentsLoaded(payments: final p) => p,
          PaymentsActionLoading(payments: final p) => p,
          PaymentVerifySuccess(payments: final p) => p,
          PaymentRejectSuccess(payments: final p) => p,
          PaymentsActionError(payments: final p) => p,
          _ => null,
        };

        if (payments == null || payments.isEmpty) {
          return const _EmptyState(
            icon: Icons.check_circle_outline_rounded,
            message: 'No verified payments yet',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSizing.pagePadding, AppSizing.sm,
              AppSizing.pagePadding, AppSizing.pagePadding),
          itemCount: payments.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSizing.md),
          itemBuilder: (context, index) {
            return PaymentCard(payment: payments[index]);
          },
        );
      },
    );
  }
}

// ── Tab 3: Rejected ───────────────────────────────────────────────────────────

class _RejectedTab extends StatelessWidget {
  const _RejectedTab({required this.args});
  final WalletPageArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentsBloc, PaymentsState>(
      builder: (context, paymentsState) {
        return BlocBuilder<PaymentRequestsBloc, PaymentRequestsState>(
          builder: (context, reqState) {
            final isLoading =
                paymentsState is PaymentsLoading || reqState is PaymentRequestsLoading;
            if (isLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
            }

            final payments = switch (paymentsState) {
              PaymentsLoaded(payments: final p) => p,
              PaymentsActionLoading(payments: final p) => p,
              PaymentVerifySuccess(payments: final p) => p,
              PaymentRejectSuccess(payments: final p) => p,
              PaymentsActionError(payments: final p) => p,
              _ => <PaymentEntity>[],
            };

            final cancelledRequests = switch (reqState) {
              PaymentRequestsLoaded(requests: final r) => r,
              PaymentRequestsActionLoading(requests: final r) => r,
              PaymentRequestCancelSuccess(requests: final r) => r,
              PaymentRequestsActionError(requests: final r) => r,
              _ => <PaymentRequestEntity>[],
            };

            if (payments.isEmpty && cancelledRequests.isEmpty) {
              return const _EmptyState(
                icon: Icons.cancel_outlined,
                message: 'No rejected or cancelled items',
              );
            }

            final itemCount = payments.length + cancelledRequests.length;

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSizing.pagePadding, AppSizing.sm,
                  AppSizing.pagePadding, AppSizing.pagePadding),
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(height: AppSizing.md),
              itemBuilder: (context, index) {
                if (index < payments.length) {
                  return PaymentCard(payment: payments[index]);
                }
                final reqIndex = index - payments.length;
                return PaymentRequestCard(
                  request: cancelledRequests[reqIndex],
                  showMemberName: args.canManage,
                );
              },
            );
          },
        );
      },
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: AppSizing.md),
          Text(
            message,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}
