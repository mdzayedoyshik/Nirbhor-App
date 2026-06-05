import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionRow extends StatelessWidget {
  const TransactionRow({super.key, required this.transaction});

  final TransactionEntity transaction;

  // ── Meta resolution ───────────────────────────────────────────────────────

  ({IconData icon, Color color, Color amountColor, String title, String prefix})
      _resolveMeta(TransactionEntity t) {
    // ── Legacy type (pre-migration records) ──────────────────────────────────
    if (t.transactionType == 'fixed_adjustment') {
      // Old description was "Fixed contribution adjustment: +333.33" or "…: -333.33"
      // A minus sign in the description means member paid less (net credit).
      final isCredit = t.description.contains(': -');
      return (
        icon: Icons.swap_vert_rounded,
        color: AppColors.warning,
        amountColor: isCredit ? AppColors.success : AppColors.warning,
        title: 'Contribution Adjusted',
        prefix: isCredit ? '+' : '−',
      );
    }

    // ── Deposit ──────────────────────────────────────────────────────────────
    if (t.isDeposit) {
      return (
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.success,
        amountColor: AppColors.success,
        title: 'Payment Received',
        prefix: '+',
      );
    }

    // ── Refund ───────────────────────────────────────────────────────────────
    if (t.isRefund) {
      return (
        icon: Icons.replay_rounded,
        color: const Color(0xFF0D9488),
        amountColor: const Color(0xFF0D9488),
        title: 'Refund',
        prefix: '+',
      );
    }

    // ── Deduction — varies by category ───────────────────────────────────────
    return switch (t.category) {
      'fixed' => (
          icon: Icons.home_rounded,
          color: AppColors.primary,
          amountColor: AppColors.error,
          title: 'Monthly Contribution',
          prefix: '−',
        ),
      'meal' => (
          icon: Icons.restaurant_rounded,
          color: AppColors.warning,
          amountColor: AppColors.error,
          title: 'Meal Expense',
          prefix: '−',
        ),
      'household' => (
          icon: Icons.handyman_rounded,
          color: const Color(0xFF8B5CF6),
          amountColor: AppColors.error,
          title: 'Household Expense',
          prefix: '−',
        ),
      _ => (
          icon: Icons.remove_circle_outline_rounded,
          color: AppColors.error,
          amountColor: AppColors.error,
          title: 'Deduction',
          prefix: '−',
        ),
    };
  }

  // ── Subtitle builder ──────────────────────────────────────────────────────

  String _buildSubtitle(TransactionEntity t) {
    final parts = <String>[];

    // Who this belongs to
    if (t.memberName != null && t.memberName!.isNotEmpty) {
      parts.add(t.memberName!);
    }

    final hint = _descriptionHint(t);
    if (hint.isNotEmpty) parts.add(hint);

    return parts.join(' · ');
  }

  /// Returns a short, clean context string from the raw description.
  /// Returns empty string when the description adds no value.
  String _descriptionHint(TransactionEntity t) {
    final raw = t.description;

    // Legacy ugly string — drop it entirely (we show "Contribution Adjusted" as title)
    if (raw.startsWith('Fixed contribution adjustment')) return '';

    // "Fixed contribution for June 2026" → "June 2026"
    const fixedPrefix = 'Fixed contribution for ';
    if (raw.startsWith(fixedPrefix)) return raw.substring(fixedPrefix.length);

    // New backend format
    if (raw == 'Contribution rate adjusted') return 'Rate change';

    // Generic strings already covered by the title row — suppress
    if (_isRedundant(raw)) return '';

    // Anything else: pass through, capped at 40 chars
    return raw.length > 40 ? '${raw.substring(0, 38)}…' : raw;
  }

  bool _isRedundant(String desc) {
    final lower = desc.toLowerCase();
    return lower == 'payment received' ||
        lower == 'deposit' ||
        lower == 'refund' ||
        lower == 'meal expense' ||
        lower == 'household expense';
  }

  // ── Amount formatter ──────────────────────────────────────────────────────

  /// Formats [amount] as a whole-taka string with comma separators.
  /// e.g. 1000000 → "1,000,000"
  String _formatAmount(double amount) {
    final String s = amount.abs().round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final meta = _resolveMeta(transaction);
    final subtitle = _buildSubtitle(transaction);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon bubble
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizing.radiusFull),
            ),
            child: Icon(meta.icon, size: 22, color: meta.color),
          ),
          const SizedBox(width: AppSizing.sm + 4),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  meta.title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.textSecColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSizing.sm),

          // Amount
          Text(
            '${meta.prefix}৳${_formatAmount(transaction.amount)}',
            style: AppTypography.titleMedium.copyWith(
              color: meta.amountColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
