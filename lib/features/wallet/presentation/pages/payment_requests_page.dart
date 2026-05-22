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
import '../../../../../core/widgets/app_text_field.dart';
import '../../../flat/domain/entities/flat_member_entity.dart';
import '../../../flat/presentation/bloc/flat_bloc.dart';
import '../../domain/entities/payment_request_entity.dart';
import '../args/submit_payment_args.dart';
import '../args/wallet_page_args.dart';
import '../bloc/payment_requests/payment_requests_bloc.dart';
import '../bloc/wallet/wallet_bloc.dart';
import '../widgets/payment_request_card.dart';

class PaymentRequestsPage extends StatefulWidget {
  const PaymentRequestsPage({super.key, required this.args});

  final WalletPageArgs args;

  @override
  State<PaymentRequestsPage> createState() => _PaymentRequestsPageState();
}

class _PaymentRequestsPageState extends State<PaymentRequestsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.args.canManage ? 3 : 1, vsync: this);
    _load('pending');
    if (widget.args.canManage) {
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          final status = switch (_tabController.index) {
            0 => 'pending',
            1 => 'paid',
            _ => 'cancelled',
          };
          _load(status);
        }
      });
    }
  }

  void _load(String? status) {
    context.read<PaymentRequestsBloc>().add(
          PaymentRequestsLoadRequested(widget.args.flatId, status: status),
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentRequestsBloc, PaymentRequestsState>(
      listener: (context, state) {
        if (state is PaymentRequestsActionError) {
          AppSnackbar.error(context, state.message);
        }
        if (state is PaymentRequestCreateSuccess) {
          AppSnackbar.success(context, AppStrings.paymentRequestSentMsg);
          context
              .read<WalletBloc>()
              .add(WalletSummaryRequested(widget.args.flatId));
        }
        if (state is PaymentRequestCancelSuccess) {
          AppSnackbar.success(context, AppStrings.paymentRequestCancelledMsg);
          context
              .read<WalletBloc>()
              .add(WalletSummaryRequested(widget.args.flatId));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text(AppStrings.paymentRequestsTitle,
                style: AppTypography.headlineMedium),
            bottom: widget.args.canManage
                ? TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'Pending'),
                      Tab(text: 'Paid'),
                      Tab(text: 'Cancelled'),
                    ],
                  )
                : null,
          ),
          floatingActionButton: widget.args.canManage
              ? FloatingActionButton.extended(
                  onPressed: () => _showCreateRequestSheet(context),
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.add, color: AppColors.white),
                  label: Text(
                    'New Request',
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.white),
                  ),
                )
              : null,
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PaymentRequestsState state) {
    if (state is PaymentRequestsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final requests = switch (state) {
      PaymentRequestsLoaded(requests: final r) => r,
      PaymentRequestsActionLoading(requests: final r) => r,
      PaymentRequestCreateSuccess(requests: final r) => r,
      PaymentRequestCancelSuccess(requests: final r) => r,
      PaymentRequestsActionError(requests: final r) => r,
      _ => null,
    };

    if (state is PaymentRequestsError) {
      return Center(
        child: Text(state.message,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
      );
    }
    if (requests == null || requests.isEmpty) {
      return Center(
        child: Text(
          'No payment requests.',
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final isActionLoading = state is PaymentRequestsActionLoading;
    final isPendingTab =
        !widget.args.canManage || _tabController.index == 0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        final status = widget.args.canManage
            ? switch (_tabController.index) {
                0 => 'pending',
                1 => 'paid',
                _ => 'cancelled',
              }
            : 'pending';
        _load(status);
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSizing.pagePadding,
            AppSizing.pagePadding,
            AppSizing.pagePadding,
            AppSizing.pagePadding + 72),
        itemCount: requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSizing.md),
        itemBuilder: (context, index) {
          final req = requests[index];
          return PaymentRequestCard(
            request: req,
            showMemberName: widget.args.canManage,
            onPayNow: !widget.args.canManage && isPendingTab && !isActionLoading
                ? () => context.push(
                      AppRoutes.walletSubmitPayment,
                      extra: SubmitPaymentArgs(
                        flatId: widget.args.flatId,
                        paymentRequestId: req.id,
                        requestedAmount: req.amount,
                        requestNote: req.note,
                        requestedByName: req.requestedByName,
                      ),
                    )
                : null,
            onCancel: widget.args.canManage && isPendingTab && !isActionLoading
                ? () => _confirmCancel(context, req)
                : null,
          );
        },
      ),
    );
  }

  void _confirmCancel(BuildContext context, PaymentRequestEntity req) {
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
                      flatId: widget.args.flatId,
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

  void _showCreateRequestSheet(BuildContext context) {
    final flat = (context.read<FlatBloc>().state is FlatLoaded)
        ? (context.read<FlatBloc>().state as FlatLoaded).flat
        : null;
    final members = flat?.activeMembers ?? <FlatMemberEntity>[];

    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String? selectedMemberId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizing.radiusLg)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius:
                        BorderRadius.circular(AppSizing.radiusFull),
                  ),
                ),
              ),
              Text(AppStrings.newPaymentRequestTitle,
                  style: AppTypography.headlineSmall),
              const SizedBox(height: AppSizing.md),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: AppStrings.requestToLabel,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizing.radiusMd)),
                ),
                initialValue: selectedMemberId,
                items: members
                    .map((m) => DropdownMenuItem(
                          value: m.flatMemberId,
                          child: Text(m.name),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setSheetState(() => selectedMemberId = v),
              ),
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
                label: AppStrings.sendRequestLabel,
                onPressed: selectedMemberId == null
                    ? null
                    : () {
                        final amount = double.tryParse(
                                amountController.text.trim()) ??
                            0;
                        if (amount <= 0) return;
                        Navigator.pop(sheetCtx);
                        context.read<PaymentRequestsBloc>().add(
                              PaymentRequestCreateRequested(
                                flatId: widget.args.flatId,
                                requestedTo: selectedMemberId!,
                                amount: amount,
                                note: noteController.text.trim().isEmpty
                                    ? null
                                    : noteController.text.trim(),
                              ),
                            );
                      },
                variant: AppButtonVariant.primary,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
