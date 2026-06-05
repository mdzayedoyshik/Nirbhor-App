import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/router/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../flat/presentation/bloc/flat_bloc.dart';
import '../../domain/entities/flat_wallet_entity.dart';
import '../args/transaction_history_args.dart';

class FlatWalletCard extends StatelessWidget {
  const FlatWalletCard({super.key, required this.flatWallet, required this.flatId});

  final FlatWalletEntity flatWallet;
  final String flatId;

  TransactionHistoryArgs _buildArgs() {
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
      flatId: flatId,
      myMemberId: member?.flatMemberId ?? '',
      members: flat?.activeMembers ?? const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNeg = flatWallet.isNegative;
    final bgColor = isNeg
        ? AppColors.error.withValues(alpha: 0.08)
        : AppColors.success.withValues(alpha: 0.08);
    final borderColor = isNeg
        ? AppColors.error.withValues(alpha: 0.25)
        : AppColors.success.withValues(alpha: 0.25);
    final textColor = isNeg ? AppColors.error : AppColors.success;

    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.walletTransactions, extra: _buildArgs()),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.md, vertical: AppSizing.sm + 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance_rounded, size: 20, color: textColor),
            const SizedBox(width: AppSizing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.flatWalletTitle,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  Text(
                    '${isNeg ? '−' : ''}৳${flatWallet.balance.abs().toStringAsFixed(0)}',
                    style: AppTypography.titleLarge.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (isNeg)
              Tooltip(
                message: AppStrings.flatWalletNegativeTooltip,
                child: Icon(Icons.warning_amber_rounded,
                    size: 18, color: AppColors.error),
              ),
            Icon(Icons.chevron_right, size: 18, color: textColor),
          ],
        ),
      ),
    );
  }
}
