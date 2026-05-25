import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../domain/entities/meal_toggle_entity.dart';
import '../bloc/meal_bloc.dart';

void showFlatToggleSheet({
  required BuildContext context,
  required String flatId,
  required String currentDate,
  required MealToggleEntity flatToggle,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizing.radiusLg)),
    ),
    builder: (sheetCtx) => BlocProvider.value(
      value: context.read<MealBloc>(),
      child: _FlatToggleSheet(
        flatId: flatId,
        currentDate: currentDate,
        flatToggle: flatToggle,
      ),
    ),
  );
}

class _FlatToggleSheet extends StatefulWidget {
  final String flatId;
  final String currentDate;
  final MealToggleEntity flatToggle;

  const _FlatToggleSheet({
    required this.flatId,
    required this.currentDate,
    required this.flatToggle,
  });

  @override
  State<_FlatToggleSheet> createState() => _FlatToggleSheetState();
}

class _FlatToggleSheetState extends State<_FlatToggleSheet> {
  late bool _breakfast;
  late bool _lunch;
  late bool _dinner;

  @override
  void initState() {
    super.initState();
    _breakfast = widget.flatToggle.isBreakfastEnabled;
    _lunch = widget.flatToggle.isLunchEnabled;
    _dinner = widget.flatToggle.isDinnerEnabled;
  }

  static const _shiftColors = {
    'breakfast': Color(0xFFF59E0B),
    'lunch': Color(0xFF10B981),
    'dinner': Color(0xFF6C63FF),
  };
  static const _shiftIcons = {
    'breakfast': Icons.wb_sunny_outlined,
    'lunch': Icons.restaurant_outlined,
    'dinner': Icons.nights_stay_outlined,
  };

  void _save() {
    context.read<MealBloc>().add(MealFlatToggleRequested(
          flatId: widget.flatId,
          body: {
            'date': widget.currentDate,
            'is_breakfast_enabled': _breakfast,
            'is_lunch_enabled': _lunch,
            'is_dinner_enabled': _dinner,
          },
        ));
    Navigator.of(context).pop();
  }

  Widget _row(String label, String shift, bool value, ValueChanged<bool> onChange) {
    final color = _shiftColors[shift]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: value
                  ? color.withValues(alpha: 0.12)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            child: Icon(
              _shiftIcons[shift],
              size: 18,
              color: value ? color : AppColors.textHint,
            ),
          ),
          const SizedBox(width: AppSizing.sm),
          Expanded(
            child: Text(label, style: AppTypography.titleMedium),
          ),
          Switch(
            value: value,
            onChanged: onChange,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizing.pagePadding,
        AppSizing.md,
        AppSizing.pagePadding,
        AppSizing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppSizing.md),
          Text('Flat Meal Shifts', style: AppTypography.titleLarge),
          Text(
            'Toggle shifts for all members on ${widget.currentDate}',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizing.md),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSizing.md),
          _row('Breakfast', 'breakfast', _breakfast,
              (v) => setState(() => _breakfast = v)),
          _row('Lunch', 'lunch', _lunch,
              (v) => setState(() => _lunch = v)),
          _row('Dinner', 'dinner', _dinner,
              (v) => setState(() => _dinner = v)),
          const SizedBox(height: AppSizing.sm),
          Container(
            padding: const EdgeInsets.all(AppSizing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppColors.warning),
                const SizedBox(width: AppSizing.xs),
                Expanded(
                  child: Text(
                    'Disabling a shift will remove it from all active member logs.',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSizing.sm + 4),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizing.radiusMd)),
              ),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}
