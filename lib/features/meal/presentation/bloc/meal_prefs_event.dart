import 'package:equatable/equatable.dart';

abstract class MealPrefsEvent extends Equatable {
  const MealPrefsEvent();
  @override
  List<Object?> get props => [];
}

class MealPrefsLoadRequested extends MealPrefsEvent {
  final String flatId;
  final String memberId;

  const MealPrefsLoadRequested({required this.flatId, required this.memberId});

  @override
  List<Object?> get props => [flatId, memberId];
}

class MealPrefsDayToggled extends MealPrefsEvent {
  final int dayOfWeek;
  final String shift; // 'breakfast' | 'lunch' | 'dinner'

  const MealPrefsDayToggled({required this.dayOfWeek, required this.shift});

  @override
  List<Object?> get props => [dayOfWeek, shift];
}

class MealPrefsSaveRequested extends MealPrefsEvent {
  final String flatId;
  final String memberId;

  const MealPrefsSaveRequested({required this.flatId, required this.memberId});

  @override
  List<Object?> get props => [flatId, memberId];
}
