import 'package:equatable/equatable.dart';

import '../../domain/entities/meal_pool_entity.dart';

abstract class MealPoolState extends Equatable {
  const MealPoolState();
  @override
  List<Object?> get props => [];
}

class MealPoolInitial extends MealPoolState {
  const MealPoolInitial();
}

class MealPoolLoading extends MealPoolState {
  const MealPoolLoading();
}

class MealPoolLoaded extends MealPoolState {
  final MealPoolEntity pool;
  final int month;
  final int year;

  const MealPoolLoaded({
    required this.pool,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [pool, month, year];
}

class MealPoolError extends MealPoolState {
  final String message;
  const MealPoolError(this.message);
  @override
  List<Object?> get props => [message];
}
