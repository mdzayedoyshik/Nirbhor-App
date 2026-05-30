import 'package:equatable/equatable.dart';

abstract class MealEvent extends Equatable {
  const MealEvent();
  @override
  List<Object?> get props => [];
}

class MealDailyLoadRequested extends MealEvent {
  final String flatId;
  final String date;

  const MealDailyLoadRequested({required this.flatId, required this.date});

  @override
  List<Object?> get props => [flatId, date];
}

class MealDailyDateChanged extends MealEvent {
  final String flatId;
  final String date;

  const MealDailyDateChanged({required this.flatId, required this.date});

  @override
  List<Object?> get props => [flatId, date];
}

class MealSelfToggleRequested extends MealEvent {
  final String flatId;
  final Map<String, dynamic> body;

  const MealSelfToggleRequested({required this.flatId, required this.body});

  @override
  List<Object?> get props => [flatId, body];
}

class MealManagerEditRequested extends MealEvent {
  final String flatId;
  final String memberId;
  final Map<String, dynamic> body;

  const MealManagerEditRequested({
    required this.flatId,
    required this.memberId,
    required this.body,
  });

  @override
  List<Object?> get props => [flatId, memberId, body];
}

class MealFlatToggleRequested extends MealEvent {
  final String flatId;
  final Map<String, dynamic> body;

  const MealFlatToggleRequested({required this.flatId, required this.body});

  @override
  List<Object?> get props => [flatId, body];
}

class MealConfigUpdateRequested extends MealEvent {
  final String flatId;
  final Map<String, dynamic> data;

  const MealConfigUpdateRequested({required this.flatId, required this.data});

  @override
  List<Object?> get props => [flatId, data];
}
