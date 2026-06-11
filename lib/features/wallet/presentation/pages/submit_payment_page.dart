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
import '../args/submit_payment_args.dart';
import '../args/wallet_page_args.dart';
import '../bloc/wallet/wallet_bloc.dart';

class SubmitPaymentPage extends StatefulWidget {
  const SubmitPaymentPage({super.key, required this.args});

  final SubmitPaymentArgs args;

  @override
  State<SubmitPaymentPage> createState() => _SubmitPaymentPageState();
}

class _SubmitPaymentPageState extends State<SubmitPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedMethod = 'bkash';

  static const _methods = ['bkash', 'nagad', 'cash', 'bank', 'other'];

  @override
  void initState() {
    super.initState();
    // Pre-fill: prefer initialAmount, fall back to the linked request's amount.
    final prefill = widget.args.initialAmount ?? widget.args.requestedAmount;
    if (prefill != null) {
      _amountController.text = prefill.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    context.read<WalletBloc>().add(WalletPaymentSubmitRequested(
          flatId: widget.args.flatId,
          amount: amount,
          paymentMethod: _selectedMethod,
          paymentRequestId: widget.args.paymentRequestId,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listenWhen: (_, curr) =>
          curr is WalletPaymentSubmitSuccess || curr is WalletError,
      listener: (context, state) {
        if (state is WalletPaymentSubmitSuccess) {
          AppSnackbar.success(context, AppStrings.paymentSubmittedMsg);
          // Replace the submit page with the Awaiting tab so the member can
          // immediately see their payment pending verification.
          context.pushReplacement(
            AppRoutes.walletRequests,
            extra: WalletPageArgs(
              flatId: widget.args.flatId,
              canManage: widget.args.canManage,
              initialTab: 1, // 1 = Awaiting
            ),
          );
        }
        if (state is WalletError) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is WalletActionLoading;
        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            backgroundColor: context.bgColor,
            elevation: 0,
            title: Text(AppStrings.submitPaymentTitle,
                style: AppTypography.headlineMedium),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizing.pagePadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linked request banner
                  if (widget.args.paymentRequestId != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSizing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius:
                            BorderRadius.circular(AppSizing.radiusMd),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: AppSizing.xs),
                          Expanded(
                            child: Text(
                              widget.args.requestedByName != null
                                  ? 'Paying request from ${widget.args.requestedByName}: ৳${widget.args.requestedAmount?.toStringAsFixed(0)}'
                                  : 'Linked to payment request: ৳${widget.args.requestedAmount?.toStringAsFixed(0)}',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizing.md),
                  ],

                  AppTextField(
                    controller: _amountController,
                    label: AppStrings.paymentAmountLabel,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Amount is required';
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizing.md),

                  Text(AppStrings.paymentMethodLabel,
                      style: AppTypography.titleMedium),
                  const SizedBox(height: AppSizing.xs),
                  Wrap(
                    spacing: AppSizing.sm,
                    children: _methods.map((m) {
                      final selected = _selectedMethod == m;
                      return ChoiceChip(
                        label: Text(m[0].toUpperCase() + m.substring(1)),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedMethod = m),
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        labelStyle: AppTypography.labelLarge.copyWith(
                          color: selected
                              ? AppColors.primary
                              : context.textPrimColor,
                        ),
                        side: BorderSide(
                          color: selected ? AppColors.primary : context.borderColor,
                        ),
                        backgroundColor: context.cardColor,
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSizing.md),

                  AppTextField(
                    controller: _noteController,
                    label: AppStrings.paymentNoteLabel,
                    hint: 'e.g. bKash TrxID: ABC123',
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSizing.xl),

                  // Confirmation preview
                  BlocBuilder<WalletBloc, WalletState>(
                    builder: (context, _) {
                      final amount = double.tryParse(
                              _amountController.text.trim()) ??
                          0;
                      if (amount <= 0) return const SizedBox.shrink();
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSizing.md),
                        margin: const EdgeInsets.only(bottom: AppSizing.md),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusMd),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'You are submitting ৳${amount.toStringAsFixed(0)} for verification',
                              style: AppTypography.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Verification may take some time.',
                              style: AppTypography.bodySmall.copyWith(
                                  color: context.textSecColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  AppButton(
                    label: AppStrings.submitPaymentLabel,
                    onPressed: isLoading ? null : _submit,
                    variant: AppButtonVariant.primary,
                    fullWidth: true,
                    loading: isLoading,
                    offlineDisabled: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
