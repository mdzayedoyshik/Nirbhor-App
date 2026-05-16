import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/flat_entity.dart';
import '../widgets/member_tile.dart';

class FlatMembersPage extends StatelessWidget {
  final FlatEntity flat;

  const FlatMembersPage({super.key, required this.flat});

  @override
  Widget build(BuildContext context) {
    final active = flat.activeMembers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.flatMembersTitle,
          style: AppTypography.titleLarge,
        ),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary strip
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppSizing.pagePadding),
            padding: const EdgeInsets.all(AppSizing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(label: 'Total Members', value: '${active.length}'),
                Container(width: 1, height: 32, color: AppColors.border),
                _SummaryItem(
                  label: AppStrings.totalExpenses,
                  value: '৳${flat.totalFixedExpenses.toStringAsFixed(0)}',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSizing.pagePadding,
                0,
                AppSizing.pagePadding,
                AppSizing.pagePadding,
              ),
              itemCount: active.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSizing.sm),
              itemBuilder: (_, i) => MemberTile(member: active[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
        ),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}
