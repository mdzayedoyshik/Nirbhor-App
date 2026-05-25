import '../../domain/entities/meal_log_entity.dart';

class MealLogModel extends MealLogEntity {
  const MealLogModel({
    required super.id,
    required super.date,
    required super.breakfast,
    required super.lunch,
    required super.dinner,
    required super.breakfastGuests,
    required super.lunchGuests,
    required super.dinnerGuests,
    required super.totalPoints,
  });

  factory MealLogModel.fromJson(Map<String, dynamic> json) => MealLogModel(
        id: json['id'] as String,
        date: json['date'] as String,
        breakfast: json['breakfast'] as bool? ?? false,
        lunch: json['lunch'] as bool? ?? false,
        dinner: json['dinner'] as bool? ?? false,
        breakfastGuests: (json['breakfast_guests'] as num?)?.toInt() ?? 0,
        lunchGuests: (json['lunch_guests'] as num?)?.toInt() ?? 0,
        dinnerGuests: (json['dinner_guests'] as num?)?.toInt() ?? 0,
        totalPoints: (json['total_points'] as num?)?.toDouble() ?? 0,
      );
}
