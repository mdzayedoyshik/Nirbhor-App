import '../../domain/entities/meal_pref_day_entity.dart';

class MealPrefDayModel extends MealPrefDayEntity {
  const MealPrefDayModel({
    required super.dayOfWeek,
    required super.dayName,
    required super.breakfast,
    required super.lunch,
    required super.dinner,
  });

  factory MealPrefDayModel.fromJson(Map<String, dynamic> json) =>
      MealPrefDayModel(
        dayOfWeek: (json['day_of_week'] as num).toInt(),
        dayName: json['day_name'] as String? ?? '',
        breakfast: json['breakfast'] as bool? ?? true,
        lunch: json['lunch'] as bool? ?? true,
        dinner: json['dinner'] as bool? ?? true,
      );
}
