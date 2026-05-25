import 'package:equatable/equatable.dart';

class MealLogEntity extends Equatable {
  const MealLogEntity({
    required this.id,
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.breakfastGuests,
    required this.lunchGuests,
    required this.dinnerGuests,
    required this.totalPoints,
  });

  final String id;
  final String date;
  final bool breakfast;
  final bool lunch;
  final bool dinner;
  final int breakfastGuests;
  final int lunchGuests;
  final int dinnerGuests;
  final double totalPoints;

  @override
  List<Object?> get props => [
        id,
        date,
        breakfast,
        lunch,
        dinner,
        breakfastGuests,
        lunchGuests,
        dinnerGuests,
        totalPoints,
      ];
}
