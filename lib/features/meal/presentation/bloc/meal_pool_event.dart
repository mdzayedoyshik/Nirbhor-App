import 'package:equatable/equatable.dart';

abstract class MealPoolEvent extends Equatable {
  const MealPoolEvent();
  @override
  List<Object?> get props => [];
}

class MealPoolLoadRequested extends MealPoolEvent {
  final String flatId;
  final int month;
  final int year;

  const MealPoolLoadRequested({
    required this.flatId,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [flatId, month, year];
}
