import 'package:equatable/equatable.dart';

class MealToggleEntity extends Equatable {
  const MealToggleEntity({
    required this.date,
    required this.isBreakfastEnabled,
    required this.isLunchEnabled,
    required this.isDinnerEnabled,
  });

  final String date;
  final bool isBreakfastEnabled;
  final bool isLunchEnabled;
  final bool isDinnerEnabled;

  bool isEnabled(String shift) => switch (shift) {
        'breakfast' => isBreakfastEnabled,
        'lunch' => isLunchEnabled,
        'dinner' => isDinnerEnabled,
        _ => true,
      };

  @override
  List<Object?> get props =>
      [date, isBreakfastEnabled, isLunchEnabled, isDinnerEnabled];
}
