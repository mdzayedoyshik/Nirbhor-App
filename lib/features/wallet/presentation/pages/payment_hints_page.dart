import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../bloc/payment_hints/payment_hints_bloc.dart';

class PaymentHintsPage extends StatefulWidget {
  const PaymentHintsPage({super.key, required this.flatId});

  final String flatId;

  @override
  State<PaymentHintsPage> createState() => _PaymentHintsPageState();
}

class _PaymentHintsPageState extends State<PaymentHintsPage> {
  final _mealController = TextEditingController();
  final _householdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context
        .read<PaymentHintsBloc>()
        .add(PaymentHintsLoadRequested(widget.flatId));
  }

  @override
  void dispose() {
    _mealController.dispose();
    _householdController.dispose();
    super.dispose();
  }

  void _save() {
    final meal = double.tryParse(_mealController.text.trim());
    final household = double.tryParse(_householdController.text.trim());
    context.read<PaymentHintsBloc>().add(
          PaymentHintsUpdateRequested(
            flatId: widget.flatId,
            suggestedMealAmount: meal,
            suggestedHouseholdAmount: household,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentHintsBloc, PaymentHintsState>(
      listener: (context, state) {
        if (state is PaymentHintsUpdateSuccess) {
          AppSnackbar.success(context, AppStrings.paymentHintsUpdatedMsg);
        }
        if (state is PaymentHintsError) {
          AppSnackbar.error(context, state.message);
        }
        if (state is PaymentHintsLoaded) {
          _mealController.text =
              state.hints.suggestedMealAmount.toStringAsFixed(0);
          _householdController.text =
              state.hints.suggestedHouseholdAmount.toStringAsFixed(0);
        }
        if (state is PaymentHintsUpdateSuccess) {
          _mealController.text =
              state.hints.suggestedMealAmount.toStringAsFixed(0);
          _householdController.text =
              state.hints.suggestedHouseholdAmount.toStringAsFixed(0);
        }
      },
      builder: (context, state) {
        final isLoading = state is PaymentHintsLoading;
        final isActionLoading = state is PaymentHintsActionLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text(AppStrings.paymentHintsTitle,
                style: AppTypography.headlineMedium),
          ),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizing.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _mealController,
                        label: AppStrings.suggestedMealLabel,
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppSizing.md),
                      AppTextField(
                        controller: _householdController,
                        label: AppStrings.suggestedHouseholdLabel,
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppSizing.lg),

                      // Helper note
                      Container(
                        padding: const EdgeInsets.all(AppSizing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusMd),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: AppSizing.xs),
                            Expanded(
                              child: Text(
                                AppStrings.paymentHintsHelperNote,
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizing.xl),

                      AppButton(
                        label: AppStrings.saveChanges,
                        onPressed: isActionLoading ? null : _save,
                        variant: AppButtonVariant.primary,
                        fullWidth: true,
                        loading: isActionLoading,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
