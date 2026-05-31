import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../flat/presentation/bloc/flat_bloc.dart';
import '../../domain/entities/settlement_entity.dart';
import '../../domain/usecases/acknowledge_exit_usecase.dart';

class ExitSummaryPage extends StatefulWidget {
  final SettlementEntity settlement;
  final String flatName;

  const ExitSummaryPage({
    super.key,
    required this.settlement,
    required this.flatName,
  });

  @override
  State<ExitSummaryPage> createState() => _ExitSummaryPageState();
}

class _ExitSummaryPageState extends State<ExitSummaryPage> {
  bool _loading = false;

  Future<void> _onClose() async {
    setState(() => _loading = true);
    try {
      await sl<AcknowledgeExitUseCase>()();
      if (!mounted) return;
      context.read<FlatBloc>().add(const FlatCheckRequested());
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, _msg(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Exit Complete', style: AppTypography.titleLarge),
        backgroundColor: context.cardColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _ExitHeader(flatName: widget.flatName),
                  const SizedBox(height: AppSizing.lg),

                  // Breakdown card
                  _BreakdownCard(settlement: widget.settlement),
                  const SizedBox(height: AppSizing.lg),

                  // Final amount card
                  _FinalAmountCard(settlement: widget.settlement),
                ],
              ),
            ),
          ),

          // Close button pinned at bottom
          Padding(
            padding: const EdgeInsets.all(AppSizing.pagePadding),
            child: AppButton(
              label: 'Close',
              loading: _loading,
              onPressed: _onClose,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Exit Header ──────────────────────────────────────────────────────────────

class _ExitHeader extends StatelessWidget {
  final String flatName;
  const _ExitHeader({required this.flatName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSizing.sm),
        Container(
          width: AppSizing.iconXl,
          height: AppSizing.iconXl,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: AppSizing.iconLg,
          ),
        ),
        const SizedBox(height: AppSizing.md),
        Text(
          'You have left $flatName',
          style: AppTypography.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizing.xs),
        Text(
          'Your exit has been finalised. Review the settlement below.',
          style: AppTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Breakdown Card ───────────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final SettlementEntity settlement;
  const _BreakdownCard({required this.settlement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Breakdown', style: AppTypography.titleLarge),
          const SizedBox(height: AppSizing.md),
          _Row(
            label: 'Meal Points',
            value: settlement.mealPoints.toStringAsFixed(1),
          ),
          Divider(height: AppSizing.md, color: context.borderColor),
          _Row(
            label: 'Meal Cost',
            value: '৳${settlement.mealCost.toStringAsFixed(2)}',
            valueColor: AppColors.error,
          ),
          const SizedBox(height: AppSizing.sm),
          _Row(
            label: 'Wallet Balance',
            value: '৳${settlement.walletBalance.toStringAsFixed(2)}',
            valueColor: AppColors.success,
          ),
          const SizedBox(height: AppSizing.sm),
          _Row(
            label: 'Fixed Refund',
            value: '৳${settlement.fixedRefund.toStringAsFixed(2)}',
            valueColor: AppColors.success,
          ),
          Divider(height: AppSizing.md, color: context.borderColor),
          _Row(
            label: 'Net Amount',
            value: '৳${settlement.finalAmount.toStringAsFixed(2)}',
            valueColor: settlement.flatOwesMember
                ? AppColors.success
                : AppColors.error,
            bold: true,
          ),
        ],
      ),
    );
  }
}

// ─── Final Amount Card ────────────────────────────────────────────────────────

class _FinalAmountCard extends StatelessWidget {
  final SettlementEntity settlement;
  const _FinalAmountCard({required this.settlement});

  @override
  Widget build(BuildContext context) {
    final flatOwes = settlement.flatOwesMember;
    final amount = settlement.finalAmount.abs();
    final color = amount == 0 ? AppColors.success : (flatOwes ? AppColors.success : AppColors.error);

    return Container(
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: AppSizing.iconMd,
          ),
          const SizedBox(width: AppSizing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fully Settled',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (amount > 0) ...[
                  const SizedBox(height: AppSizing.xs),
                  Text(
                    flatOwes
                        ? '৳${amount.toStringAsFixed(2)} to be collected from flat'
                        : '৳${amount.toStringAsFixed(2)} to be paid to flat',
                    style: AppTypography.bodySmall.copyWith(color: color),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Row ──────────────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _Row({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTypography.titleMedium : AppTypography.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          value,
          style: style.copyWith(
            color: valueColor,
            fontWeight: bold ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}
