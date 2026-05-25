import 'package:equatable/equatable.dart';

class MealPrefDayEntity extends Equatable {
  const MealPrefDayEntity({
    required this.dayOfWeek,
    required this.dayName,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  final int dayOfWeek; // 0=Sun, 6=Sat
  final String dayName;
  final bool breakfast;
  final bool lunch;
  final bool dinner;

  MealPrefDayEntity copyWith({bool? breakfast, bool? lunch, bool? dinner}) =>
      MealPrefDayEntity(
        dayOfWeek: dayOfWeek,
        dayName: dayName,
        breakfast: breakfast ?? this.breakfast,
        lunch: lunch ?? this.lunch,
        dinner: dinner ?? this.dinner,
      );

  @override
  List<Object?> get props => [dayOfWeek, dayName, breakfast, lunch, dinner];
}
