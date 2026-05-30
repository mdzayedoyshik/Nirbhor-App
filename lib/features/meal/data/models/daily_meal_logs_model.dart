import '../../domain/entities/daily_log_entry_entity.dart';
import '../../domain/entities/daily_meal_logs_entity.dart';
import '../../domain/entities/meal_toggle_entity.dart';
import 'meal_toggle_model.dart';

class DailyMealLogsModel extends DailyMealLogsEntity {
  const DailyMealLogsModel({
    required super.date,
    required super.flatToggle,
    required super.shiftTotals,
    required super.logs,
  });

  factory DailyMealLogsModel.fromJson(Map<String, dynamic> json) {
    final toggleJson = json['flat_toggle'] as Map<String, dynamic>?;
    final toggle = toggleJson != null
        ? MealToggleModel.fromJson({...toggleJson, 'date': json['date'] ?? ''})
        : MealToggleEntity(
            date: json['date'] as String? ?? '',
            isBreakfastEnabled: true,
            isLunchEnabled: true,
            isDinnerEnabled: true,
          );

    final totalsJson = json['shift_totals'] as Map<String, dynamic>? ?? {};
    final totals = ShiftTotalsEntity(
      breakfast: _parseCount(totalsJson['breakfast']),
      lunch: _parseCount(totalsJson['lunch']),
      dinner: _parseCount(totalsJson['dinner']),
    );

    final logsJson = json['logs'] as List? ?? [];
    final logs = logsJson
        .map((e) => _parseEntry(e as Map<String, dynamic>))
        .toList();

    return DailyMealLogsModel(
      date: json['date'] as String? ?? '',
      flatToggle: toggle,
      shiftTotals: totals,
      logs: logs,
    );
  }

  static ShiftCountEntity _parseCount(dynamic raw) {
    if (raw == null) {
      return const ShiftCountEntity(members: 0, guests: 0, totalServings: 0);
    }
    final m = raw as Map<String, dynamic>;
    return ShiftCountEntity(
      members: (m['members'] as num?)?.toInt() ?? 0,
      guests: (m['guests'] as num?)?.toInt() ?? 0,
      totalServings: (m['total_servings'] as num?)?.toInt() ?? 0,
    );
  }

  static DailyLogEntryEntity _parseEntry(Map<String, dynamic> m) =>
      DailyLogEntryEntity(
        id: m['id'] as String?,
        flatMemberId: m['flat_member_id'] as String,
        memberName: m['member_name'] as String? ?? '',
        breakfast: m['breakfast'] as bool? ?? false,
        lunch: m['lunch'] as bool? ?? false,
        dinner: m['dinner'] as bool? ?? false,
        breakfastGuests: (m['breakfast_guests'] as num?)?.toInt() ?? 0,
        lunchGuests: (m['lunch_guests'] as num?)?.toInt() ?? 0,
        dinnerGuests: (m['dinner_guests'] as num?)?.toInt() ?? 0,
        totalPoints: (m['total_points'] as num?)?.toDouble() ?? 0,
        isPreferenceBased: m['is_preference_based'] as bool? ?? false,
      );
}
