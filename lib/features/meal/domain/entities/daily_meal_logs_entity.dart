import 'package:equatable/equatable.dart';

import 'daily_log_entry_entity.dart';
import 'meal_toggle_entity.dart';

class DailyMealLogsEntity extends Equatable {
  const DailyMealLogsEntity({
    required this.date,
    required this.flatToggle,
    required this.shiftTotals,
    required this.logs,
  });

  final String date;
  final MealToggleEntity flatToggle;
  final ShiftTotalsEntity shiftTotals;
  final List<DailyLogEntryEntity> logs;

  @override
  List<Object?> get props => [date, flatToggle, shiftTotals, logs];
}
