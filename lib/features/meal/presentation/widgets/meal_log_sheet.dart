import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../domain/entities/daily_log_entry_entity.dart';
import '../../domain/entities/meal_config_entity.dart';
import '../../domain/entities/meal_toggle_entity.dart';
import '../bloc/meal_bloc.dart';

// ── Shift definitions ──────────────────────────────────────────────────────────

const _shifts = ['breakfast', 'lunch', 'dinner'];
const _shiftLabels = {'breakfast': 'Breakfast', 'lunch': 'Lunch', 'dinner': 'Dinner'};
const _shiftIcons = {
  'breakfast': Icons.wb_sunny_outlined,
  'lunch': Icons.restaurant_outlined,
  'dinner': Icons.nights_stay_outlined,
};
const _shiftColors = {
  'breakfast': Color(0xFFF59E0B),
  'lunch': Color(0xFF10B981),
  'dinner': Color(0xFF6C63FF),
};

// ── Public show helper ─────────────────────────────────────────────────────────

void showMealLogSheet({
  required BuildContext context,
  required String flatId,
  required String currentDate,
  required DailyLogEntryEntity entry,
  required MealConfigEntity config,
  required MealToggleEntity flatToggle,
  required bool isManager,
  required bool isOwn,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.sheetBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizing.radiusLg)),
    ),
    builder: (sheetCtx) => BlocProvider.value(
      value: context.read<MealBloc>(),
      child: _MealLogSheet(
        flatId: flatId,
        currentDate: currentDate,
        entry: entry,
        config: config,
        flatToggle: flatToggle,
        isManager: isManager,
        isOwn: isOwn,
      ),
    ),
  );
}

class _MealLogSheet extends StatefulWidget {
  final String flatId;
  final String currentDate;
  final DailyLogEntryEntity entry;
  final MealConfigEntity config;
  final MealToggleEntity flatToggle;
  final bool isManager;
  final bool isOwn;

  const _MealLogSheet({
    required this.flatId,
    required this.currentDate,
    required this.entry,
    required this.config,
    required this.flatToggle,
    required this.isManager,
    required this.isOwn,
  });

  @override
  State<_MealLogSheet> createState() => _MealLogSheetState();
}

class _MealLogSheetState extends State<_MealLogSheet> {
  late Map<String, bool> _on;
  late Map<String, int> _guests;
  // per-shift pending save debounce timers
  final Map<String, Timer?> _debounce = {};

  @override
  void initState() {
    super.initState();
    _on = {
      'breakfast': widget.entry.breakfast,
      'lunch': widget.entry.lunch,
      'dinner': widget.entry.dinner,
    };
    _guests = {
      'breakfast': widget.entry.breakfastGuests,
      'lunch': widget.entry.lunchGuests,
      'dinner': widget.entry.dinnerGuests,
    };
  }

  @override
  void dispose() {
    for (final t in _debounce.values) {
      t?.cancel();
    }
    super.dispose();
  }

  bool _shiftEditable(String shift) {
    if (!widget.flatToggle.isEnabled(shift)) return false;
    if (widget.isManager) return true;
    return !widget.config.isLocked(shift);
  }

  String? _shiftHint(String shift) {
    if (!widget.flatToggle.isEnabled(shift)) return 'Disabled by manager';
    if (!widget.isManager && widget.config.isLocked(shift)) {
      return 'Locked — deadline passed';
    }
    return null;
  }

  void _toggle(String shift) {
    if (!_shiftEditable(shift)) return;
    setState(() {
      _on[shift] = !(_on[shift] ?? false);
      if (!(_on[shift]!)) _guests[shift] = 0;
    });
    // cancel pending guest debounce for this shift and save immediately
    _debounce[shift]?.cancel();
    _autoSave(shift);
  }

  void _adjustGuests(String shift, int delta) {
    if (!_shiftEditable(shift) || !(_on[shift] ?? false)) return;
    final current = _guests[shift] ?? 0;
    final next = (current + delta).clamp(0, 10);
    if (next == current) return;
    setState(() => _guests[shift] = next);
    _debounce[shift]?.cancel();
    _debounce[shift] = Timer(
      const Duration(milliseconds: 500),
      () => _autoSave(shift),
    );
  }

  void _autoSave(String shift) {
    if (!mounted) return;
    final body = <String, dynamic>{'date': widget.currentDate};
    if (widget.isManager && !widget.isOwn) {
      // manager editing another member: always send full state
      for (final s in _shifts) {
        body[s] = _on[s];
        body['${s}_guests'] = _guests[s];
      }
    } else {
      // send only the changed shift
      body[shift] = _on[shift];
      body['${shift}_guests'] = _guests[shift];
    }
    if (widget.isManager && !widget.isOwn) {
      context.read<MealBloc>().add(MealManagerEditRequested(
            flatId: widget.flatId,
            memberId: widget.entry.flatMemberId,
            body: body,
          ));
    } else {
      context.read<MealBloc>().add(
            MealSelfToggleRequested(flatId: widget.flatId, body: body),
          );
    }
  }

  void _done() {
    for (final t in _debounce.values) {
      t?.cancel();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizing.pagePadding,
        right: AppSizing.pagePadding,
        top: AppSizing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(AppSizing.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppSizing.md),

          // header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entry.memberName.isEmpty
                          ? 'My Meals'
                          : widget.entry.memberName,
                      style: AppTypography.titleLarge,
                    ),
                    Text(
                      widget.currentDate,
                      style: AppTypography.bodySmall
                          .copyWith(color: context.textSecColor),
                    ),
                  ],
                ),
              ),
              if (widget.entry.isPreferenceBased)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.textSecColor.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppSizing.radiusFull),
                    border: Border.all(
                        color: context.textSecColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Expected',
                    style: AppTypography.labelSmall
                        .copyWith(color: context.textSecColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizing.md),
          Divider(color: context.borderColor, height: 1),
          const SizedBox(height: AppSizing.md),

          // shift rows
          ...List.generate(_shifts.length, (i) {
            final shift = _shifts[i];
            final editable = _shiftEditable(shift);
            final hint = _shiftHint(shift);
            final isOn = _on[shift] ?? false;
            final guestCount = _guests[shift] ?? 0;
            final color = _shiftColors[shift]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (editable && isOn)
                              ? color.withValues(alpha: 0.12)
                              : context.surfaceColor,
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusMd),
                        ),
                        child: Icon(
                          _shiftIcons[shift],
                          size: 18,
                          color: (editable && isOn)
                              ? color
                              : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(width: AppSizing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_shiftLabels[shift]!,
                                style: AppTypography.titleMedium),
                            if (hint != null)
                              Text(hint,
                                  style: AppTypography.labelSmall.copyWith(
                                      color: context.textSecColor)),
                          ],
                        ),
                      ),
                      if (editable)
                        Switch(
                          value: isOn,
                          onChanged: (_) => _toggle(shift),
                          activeThumbColor: color,
                          activeTrackColor: color.withValues(alpha: 0.35),
                          inactiveThumbColor: AppColors.textHint,
                          inactiveTrackColor: context.borderColor,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        )
                      else
                        Icon(Icons.lock_outline,
                            size: 18, color: AppColors.textHint),
                    ],
                  ),
                  // Guest counter (shown when on + editable)
                  if (editable && isOn) ...[
                    const SizedBox(height: AppSizing.sm),
                    Padding(
                      padding: const EdgeInsets.only(left: 44),
                      child: Row(
                        children: [
                          Text(
                            'Guests',
                            style: AppTypography.bodySmall
                                .copyWith(color: context.textSecColor),
                          ),
                          const Spacer(),
                          _GuestCounter(
                            count: guestCount,
                            onDecrement: () => _adjustGuests(shift, -1),
                            onIncrement: () => _adjustGuests(shift, 1),
                            color: color,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: AppSizing.sm),
          // BlocBuilder for inline action feedback
          BlocBuilder<MealBloc, MealState>(
            builder: (context, state) {
              final isSaving = state is MealActionInProgress;
              return SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSaving ? null : _done,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: AppSizing.sm + 4),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizing.radiusMd)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white),
                        )
                      : const Text('Done'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Guest counter widget ───────────────────────────────────────────────────────

class _GuestCounter extends StatelessWidget {
  final int count;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final Color color;

  const _GuestCounter({
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CounterBtn(
          icon: Icons.remove,
          onTap: count > 0 ? onDecrement : null,
          color: color,
        ),
        Container(
          width: 36,
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: AppTypography.titleMedium.copyWith(color: color),
          ),
        ),
        _CounterBtn(
          icon: Icons.add,
          onTap: count < 10 ? onIncrement : null,
          color: color,
        ),
      ],
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _CounterBtn({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withValues(alpha: 0.1)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          border: Border.all(
            color: onTap != null
                ? color.withValues(alpha: 0.3)
                : context.borderColor,
          ),
        ),
        child: Icon(icon,
            size: 16,
            color:
                onTap != null ? color : AppColors.textHint),
      ),
    );
  }
}
