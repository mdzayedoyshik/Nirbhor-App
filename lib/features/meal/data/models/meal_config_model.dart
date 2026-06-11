import '../../domain/entities/meal_config_entity.dart';

class MealConfigModel extends MealConfigEntity {
  const MealConfigModel({
    required super.id,
    required super.flatId,
    required super.breakfastPoints,
    required super.lunchPoints,
    required super.dinnerPoints,
    required super.lockTimeBreakfast,
    required super.lockTimeLunch,
    required super.lockTimeDinner,
    required super.flatTimezone,
  });

  factory MealConfigModel.fromJson(Map<String, dynamic> json) =>
      MealConfigModel(
        id: json['id'] as String,
        flatId: json['flat_id'] as String,
        breakfastPoints: (json['breakfast_points'] as num).toDouble(),
        lunchPoints: (json['lunch_points'] as num).toDouble(),
        dinnerPoints: (json['dinner_points'] as num).toDouble(),
        lockTimeBreakfast: json['lock_time_breakfast'] as String? ?? '08:00',
        lockTimeLunch: json['lock_time_lunch'] as String? ?? '12:00',
        lockTimeDinner: json['lock_time_dinner'] as String? ?? '21:00',
        flatTimezone: json['flat_timezone'] as String? ?? 'Asia/Dhaka',
      );
}
