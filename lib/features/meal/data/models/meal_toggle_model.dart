import '../../domain/entities/meal_toggle_entity.dart';

class MealToggleModel extends MealToggleEntity {
  const MealToggleModel({
    required super.date,
    required super.isBreakfastEnabled,
    required super.isLunchEnabled,
    required super.isDinnerEnabled,
  });

  factory MealToggleModel.fromJson(Map<String, dynamic> json) =>
      MealToggleModel(
        date: json['date'] as String? ?? '',
        isBreakfastEnabled: json['is_breakfast_enabled'] as bool? ?? true,
        isLunchEnabled: json['is_lunch_enabled'] as bool? ?? true,
        isDinnerEnabled: json['is_dinner_enabled'] as bool? ?? true,
      );
}
