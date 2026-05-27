import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/meal_toggle_entity.dart';
import '../../domain/usecases/get_meal_config_usecase.dart';
import '../../domain/usecases/update_meal_config_usecase.dart';
import '../bloc/meal_bloc.dart';

void showFlatToggleSheet({
  required BuildContext context,
  required String flatId,
  required String currentDate,
  required MealToggleEntity flatToggle,
  bool canManage = false,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizing.radiusLg)),
    ),
    builder: (sheetCtx) => BlocProvider.value(
      value: context.read<MealBloc>(),
      child: _FlatToggleSheet(
        flatId: flatId,
        currentDate: currentDate,
        flatToggle: flatToggle,
        canManage: canManage,
      ),
    ),
  );
}

class _FlatToggleSheet extends StatefulWidget {
  final String flatId;
  final String currentDate;
  final MealToggleEntity flatToggle;
  final bool canManage;

  const _FlatToggleSheet({
    required this.flatId,
    required this.currentDate,
    required this.flatToggle,
    required this.canManage,
  });

  @override
  State<_FlatToggleSheet> createState() => _FlatToggleSheetState();
}

class _FlatToggleSheetState extends State<_FlatToggleSheet> {
  late bool _breakfast;
  late bool _lunch;
  late bool _dinner;

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

  @override
  void initState() {
    super.initState();
    _breakfast = widget.flatToggle.isBreakfastEnabled;
    _lunch = widget.flatToggle.isLunchEnabled;
    _dinner = widget.flatToggle.isDinnerEnabled;
  }

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
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSizing.pagePadding,
        AppSizing.md,
        AppSizing.pagePadding,
        AppSizing.lg + MediaQuery.of(context).viewInsets.bottom,
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

          // Lock times section — managers only
          if (widget.canManage) ...[
            const SizedBox(height: AppSizing.lg),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: AppSizing.md),
            _LockTimesSection(flatId: widget.flatId),
          ],
        ],
      ),
    );
  }
}

// ── Lock times section (manager only) ────────────────────────────────────────

class _LockTimesSection extends StatefulWidget {
  const _LockTimesSection({required this.flatId});
  final String flatId;

  @override
  State<_LockTimesSection> createState() => _LockTimesSectionState();
}

class _LockTimesSectionState extends State<_LockTimesSection> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String _savedBreakfast = '';
  String _savedLunch = '';
  String _savedDinner = '';

  String _breakfast = '';
  String _lunch = '';
  String _dinner = '';

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

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await sl<GetMealConfigUseCase>()(widget.flatId);
      if (!mounted) return;
      setState(() {
        _savedBreakfast = config.lockTimeBreakfast;
        _savedLunch = config.lockTimeLunch;
        _savedDinner = config.lockTimeDinner;
        _breakfast = config.lockTimeBreakfast;
        _lunch = config.lockTimeLunch;
        _dinner = config.lockTimeDinner;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool get _isDirty =>
      _breakfast != _savedBreakfast ||
      _lunch != _savedLunch ||
      _dinner != _savedDinner;

  TimeOfDay? _parseTime(String hhmm) {
    if (hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(
    String shift,
    String current,
    void Function(String) onPicked,
  ) async {
    final initial = _parseTime(current) ?? const TimeOfDay(hour: 0, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Set UTC lock time for $shift',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => onPicked(_formatTimeOfDay(picked)));
    }
  }

  Future<void> _save() async {
    if (!_isDirty || _saving) return;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{};
      if (_breakfast != _savedBreakfast) {
        payload['lock_time_breakfast'] = _breakfast;
      }
      if (_lunch != _savedLunch) {
        payload['lock_time_lunch'] = _lunch;
      }
      if (_dinner != _savedDinner) {
        payload['lock_time_dinner'] = _dinner;
      }
      final updated =
          await sl<UpdateMealConfigUseCase>()(widget.flatId, payload);
      if (!mounted) return;
      setState(() {
        _savedBreakfast = updated.lockTimeBreakfast;
        _savedLunch = updated.lockTimeLunch;
        _savedDinner = updated.lockTimeDinner;
        _breakfast = updated.lockTimeBreakfast;
        _lunch = updated.lockTimeLunch;
        _dinner = updated.lockTimeDinner;
        _saving = false;
      });
      if (mounted) AppSnackbar.success(context, 'Lock times updated.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizing.r8),
              ),
              child: const Icon(Icons.lock_clock_rounded,
                  size: 16, color: AppColors.brand),
            ),
            const SizedBox(width: AppSizing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meal Lock Times',
                    style: AppTypography.labelL
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  Text(
                    'UTC cut-off times for each shift',
                    style: AppTypography.labelS
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizing.md),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizing.sm),
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.brand),
            ),
          )
        else if (_error != null)
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 16, color: AppColors.error),
              const SizedBox(width: AppSizing.xs),
              Expanded(
                child: Text(
                  'Failed to load config',
                  style:
                      AppTypography.labelS.copyWith(color: AppColors.error),
                ),
              ),
              TextButton(onPressed: _loadConfig, child: const Text('Retry')),
            ],
          )
        else ...[
          _LockTimeRow(
            shift: 'breakfast',
            icon: _shiftIcons['breakfast']!,
            color: _shiftColors['breakfast']!,
            label: 'Breakfast',
            time: _breakfast,
            enabled: !_saving,
            onTap: () =>
                _pickTime('breakfast', _breakfast, (v) => _breakfast = v),
          ),
          const SizedBox(height: AppSizing.sm),
          _LockTimeRow(
            shift: 'lunch',
            icon: _shiftIcons['lunch']!,
            color: _shiftColors['lunch']!,
            label: 'Lunch',
            time: _lunch,
            enabled: !_saving,
            onTap: () => _pickTime('lunch', _lunch, (v) => _lunch = v),
          ),
          const SizedBox(height: AppSizing.sm),
          _LockTimeRow(
            shift: 'dinner',
            icon: _shiftIcons['dinner']!,
            color: _shiftColors['dinner']!,
            label: 'Dinner',
            time: _dinner,
            enabled: !_saving,
            onTap: () => _pickTime('dinner', _dinner, (v) => _dinner = v),
          ),
          if (_isDirty || _saving) ...[
            const SizedBox(height: AppSizing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSizing.sm + 2),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizing.radiusMd)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : const Text('Save Lock Times',
                        style: TextStyle(color: AppColors.white)),
              ),
            ),
          ],
        ],
        const SizedBox(height: AppSizing.sm),
      ],
    );
  }
}

class _LockTimeRow extends StatelessWidget {
  final String shift;
  final IconData icon;
  final Color color;
  final String label;
  final String time;
  final bool enabled;
  final VoidCallback onTap;

  const _LockTimeRow({
    required this.shift,
    required this.icon,
    required this.color,
    required this.label,
    required this.time,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.sm, vertical: AppSizing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizing.r8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizing.r8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: AppSizing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelM
                    .copyWith(color: AppColors.textPrimary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizing.sm, vertical: AppSizing.xs),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(AppSizing.r8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time.isEmpty ? '--:--' : time,
                    style: AppTypography.labelM.copyWith(
                      color: time.isEmpty
                          ? AppColors.textDisabled
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSizing.xs),
                  Icon(
                    Icons.edit_rounded,
                    size: 12,
                    color: enabled
                        ? AppColors.textSecondary
                        : AppColors.textDisabled,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
