import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/daily_log_entry_entity.dart';
import '../../domain/entities/meal_config_entity.dart';
import '../../domain/entities/meal_toggle_entity.dart';
import 'meal_log_sheet.dart';

const _shiftColors = {
  'breakfast': Color(0xFFF59E0B),
  'lunch': Color(0xFF10B981),
  'dinner': Color(0xFF6C63FF),
};
const _shiftIcons = {
  'breakfast': Icons.wb_sunny_rounded,
  'lunch': Icons.restaurant_rounded,
  'dinner': Icons.nights_stay_rounded,
};

class MemberMealRow extends StatelessWidget {
  const MemberMealRow({
    super.key,
    required this.flatId,
    required this.currentDate,
    required this.entry,
    required this.config,
    required this.flatToggle,
    required this.isManager,
    required this.isOwn,
    required this.isToday,
  });

  final String flatId;
  final String currentDate;
  final DailyLogEntryEntity entry;
  final MealConfigEntity config;
  final MealToggleEntity flatToggle;
  final bool isManager;
  final bool isOwn;
  final bool isToday;

  bool get _tappable =>
      isManager || (isOwn && isToday);

  void _onTap(BuildContext context) {
    if (!_tappable) return;
    showMealLogSheet(
      context: context,
      flatId: flatId,
      currentDate: currentDate,
      entry: entry,
      config: config,
      flatToggle: flatToggle,
      isManager: isManager,
      isOwn: isOwn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tappable ? () => _onTap(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.md, vertical: AppSizing.sm + 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Avatar
            AppAvatar(
              name: entry.memberName,
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              textColor: AppColors.primary,
            ),
            const SizedBox(width: AppSizing.sm),

            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.memberName,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Guest indicator
                  if (_totalGuests > 0)
                    Text(
                      '$_totalGuests guest${_totalGuests > 1 ? 's' : ''}',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),

            // Shift icons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: ['breakfast', 'lunch', 'dinner'].map((shift) {
                final active = entry.shiftEnabled(shift) &&
                    flatToggle.isEnabled(shift);
                final color = _shiftColors[shift]!;
                return Padding(
                  padding: const EdgeInsets.only(left: AppSizing.xs),
                  child: _ShiftDot(
                    icon: _shiftIcons[shift]!,
                    active: active,
                    color: color,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(width: AppSizing.sm),

            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.totalPoints.toStringAsFixed(1),
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'pts',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),

            if (_tappable) ...[
              const SizedBox(width: AppSizing.xs),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textHint,
              ),
            ],
          ],
        ),
      ),
    );
  }

  int get _totalGuests =>
      entry.breakfastGuests + entry.lunchGuests + entry.dinnerGuests;
}

class _ShiftDot extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;

  const _ShiftDot({
    required this.icon,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.12) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      ),
      child: Icon(
        icon,
        size: 14,
        color: active ? color : AppColors.textHint,
      ),
    );
  }
}
