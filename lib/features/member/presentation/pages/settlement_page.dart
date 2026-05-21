import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/finalize_exit_entity.dart';
import '../../domain/entities/settlement_entity.dart';
import '../../domain/usecases/cancel_exit_usecase.dart';
import '../../domain/usecases/finalize_exit_usecase.dart';
import '../args/settlement_page_args.dart';

class SettlementPage extends StatefulWidget {
  final SettlementPageArgs args;

  const SettlementPage({super.key, required this.args});

  @override
  State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  bool _loading = false;

  SettlementEntity get _settlement => widget.args.settlement;
  bool get _isManager => widget.args.isManager;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settlement Summary', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Final amount badge
            _FinalAmountCard(settlement: _settlement),
            const SizedBox(height: AppSizing.lg),

            // Breakdown card
            _BreakdownCard(settlement: _settlement),
            const SizedBox(height: AppSizing.lg),

            // Status chip
            Center(
              child: _StatusChip(status: _settlement.status),
            ),

            if (_isManager && _settlement.isPending) ...[
              const SizedBox(height: AppSizing.xl),
              AppButton(
                label: 'Finalise Exit',
                loading: _loading,
                onPressed: _onFinalise,
              ),
              const SizedBox(height: AppSizing.sm),
              AppButton(
                label: 'Cancel Exit',
                variant: AppButtonVariant.outlined,
                loading: _loading,
                onPressed: _onCancel,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onFinalise() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Finalise Exit',
      message:
          'This is irreversible. ${_settlement.memberName} will be removed from the flat and remaining members\' wallets will be adjusted.',
      confirmLabel: 'Finalise',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final result = await sl<FinalizeExitUseCase>()(
        flatId: widget.args.flatId,
        memberId: widget.args.memberId,
      );
      if (!mounted) return;
      await _showDeductionsSummary(context, result);
      if (!mounted) return;
      context.pop({'finalized': true});
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, _msg(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onCancel() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Cancel Exit?',
      message:
          'This will cancel the exit process and ${_settlement.memberName} will regain full access.',
      confirmLabel: 'Cancel Exit',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await sl<CancelExitUseCase>()(
        flatId: widget.args.flatId,
        memberId: widget.args.memberId,
      );
      if (!mounted) return;
      AppSnackbar.success(context, 'Exit cancelled.');
      context.pop({'cancelled': true});
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, _msg(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDeductionsSummary(
    BuildContext context,
    FinalizeExitEntity result,
  ) async {
    if (result.remainingMemberDeductions.isEmpty) return;
    final lines = result.remainingMemberDeductions
        .map((d) => '${d.name}: −৳${d.deducted.toStringAsFixed(2)}')
        .join('\n');
    await AppDialog.info(
      context: context,
      title: 'Wallet Adjustments',
      message: 'The following members were debited for the refund:\n\n$lines',
    );
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
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
    final color = flatOwes ? AppColors.success : AppColors.error;
    final icon = flatOwes ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final direction = flatOwes
        ? 'Flat owes ${settlement.memberName}'
        : '${settlement.memberName} owes flat';

    return Container(
      padding: const EdgeInsets.all(AppSizing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppSizing.iconLg),
          const SizedBox(height: AppSizing.sm),
          Text(
            '৳${amount.toStringAsFixed(2)}',
            style: AppTypography.headlineLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizing.xs),
          Text(
            direction,
            style: AppTypography.bodyMedium.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Breakdown',
            style: AppTypography.titleLarge,
          ),
          const SizedBox(height: AppSizing.md),
          _Row(
            label: 'Meal Points',
            value: settlement.mealPoints.toStringAsFixed(1),
          ),
          const Divider(height: AppSizing.md, color: AppColors.border),
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
          const Divider(height: AppSizing.md, color: AppColors.border),
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
    final style = bold
        ? AppTypography.titleMedium
        : AppTypography.bodyMedium;
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

// ─── Status Chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    final color = isPending ? AppColors.warning : AppColors.success;
    final label = isPending ? 'Pending Settlement' : 'Settled';
    final icon = isPending ? Icons.hourglass_top_rounded : Icons.check_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.md,
        vertical: AppSizing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizing.iconSm, color: color),
          const SizedBox(width: AppSizing.xs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
