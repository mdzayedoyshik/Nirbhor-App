import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../flat/domain/entities/flat_entity.dart';
import '../../../flat/presentation/bloc/flat_bloc.dart';
import '../../domain/entities/settlement_entity.dart';

class PendingExitPage extends StatefulWidget {
  final FlatEntity flat;
  final SettlementEntity settlement;

  const PendingExitPage({
    super.key,
    required this.flat,
    required this.settlement,
  });

  @override
  State<PendingExitPage> createState() => _PendingExitPageState();
}

class _PendingExitPageState extends State<PendingExitPage> {
  Future<void> _refresh() async {
    context.read<FlatBloc>().add(const FlatCheckRequested());
    // Give the bloc a moment to emit before the indicator dismisses.
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Exit in Progress', style: AppTypography.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppColors.textPrimary),
            tooltip: 'Profile',
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner
              _ExitBanner(flatName: widget.flat.name),
              const SizedBox(height: AppSizing.lg),

              // Settlement breakdown
              _BreakdownCard(settlement: widget.settlement),
              const SizedBox(height: AppSizing.lg),

              // Final amount
              _FinalAmountCard(settlement: widget.settlement),
              const SizedBox(height: AppSizing.xl),

              // Info note
              const _InfoNote(
                message:
                    'Contact your manager to finalise or cancel your exit. '
                    'Your access to flat features is restricted until the exit is resolved.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Exit Banner ──────────────────────────────────────────────────────────────

class _ExitBanner extends StatelessWidget {
  final String flatName;
  const _ExitBanner({required this.flatName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            color: AppColors.warning,
            size: AppSizing.iconMd,
          ),
          const SizedBox(width: AppSizing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exit in Progress',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizing.xs),
                Text(
                  flatName,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
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
          Text('Breakdown', style: AppTypography.titleLarge),
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

// ─── Final Amount Card ────────────────────────────────────────────────────────

class _FinalAmountCard extends StatelessWidget {
  final SettlementEntity settlement;
  const _FinalAmountCard({required this.settlement});

  @override
  Widget build(BuildContext context) {
    final flatOwes = settlement.flatOwesMember;
    final amount = settlement.finalAmount.abs();
    final color = flatOwes ? AppColors.success : AppColors.error;
    final icon = flatOwes
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
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

// ─── Info Note ────────────────────────────────────────────────────────────────

class _InfoNote extends StatelessWidget {
  final String message;
  const _InfoNote({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textSecondary,
            size: AppSizing.iconMd,
          ),
          const SizedBox(width: AppSizing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall,
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
