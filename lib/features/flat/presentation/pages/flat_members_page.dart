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
          // ── Gradient hero card ──────────────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppSizing.pagePadding),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.lg,
              vertical: AppSizing.md + 4,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppSizing.radiusLg),
              boxShadow: AppColors.shadowMd,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HeroStat(
                  icon: Icons.people_alt_outlined,
                  label: 'Total Members',
                  value: '${active.length}',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.white.withValues(alpha: 0.3),
                ),
                _HeroStat(
                  icon: Icons.receipt_long_outlined,
                  label: AppStrings.totalExpenses,
                  value: '৳${flat.totalFixedExpenses.toStringAsFixed(0)}',
                ),
              ],
            ),
          ),

          // ── Member list ─────────────────────────────────────────────────
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
              itemBuilder: (_, i) => _StyledMemberCard(member: active[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero stat item ─────────────────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.white.withValues(alpha: 0.85), size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTypography.amountL.copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelS.copyWith(
            color: AppColors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

// ── Styled member card ─────────────────────────────────────────────────────────

class _StyledMemberCard extends StatelessWidget {
  final dynamic member; // FlatMemberEntity

  const _StyledMemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        boxShadow: AppColors.shadowSm,
      ),
      child: MemberTile(member: member),
    );
  }
}
