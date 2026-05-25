import 'package:equatable/equatable.dart';

import '../../domain/entities/daily_meal_logs_entity.dart';
import '../../domain/entities/meal_config_entity.dart';

abstract class MealState extends Equatable {
  const MealState();
  @override
  List<Object?> get props => [];
}

class MealInitial extends MealState {
  const MealInitial();
}

class MealLoading extends MealState {
  const MealLoading();
}

class MealLoadError extends MealState {
  final String message;
  const MealLoadError(this.message);
  @override
  List<Object?> get props => [message];
}

class MealDailyLoaded extends MealState {
  final MealConfigEntity config;
  final DailyMealLogsEntity logs;
  final String currentDate;

  const MealDailyLoaded({
    required this.config,
    required this.logs,
    required this.currentDate,
  });

  @override
  List<Object?> get props => [config, logs, currentDate];
}

class MealActionInProgress extends MealState {
  final MealConfigEntity config;
  final DailyMealLogsEntity logs;
  final String currentDate;

  const MealActionInProgress({
    required this.config,
    required this.logs,
    required this.currentDate,
  });

  @override
  List<Object?> get props => [config, logs, currentDate];
}

class MealActionSuccess extends MealState {
  final MealConfigEntity config;
  final DailyMealLogsEntity logs;
  final String currentDate;
  final String message;

  const MealActionSuccess({
    required this.config,
    required this.logs,
    required this.currentDate,
    required this.message,
  });

  @override
  List<Object?> get props => [config, logs, currentDate, message];
}

class MealActionError extends MealState {
  final MealConfigEntity config;
  final DailyMealLogsEntity logs;
  final String currentDate;
  final String message;

  const MealActionError({
    required this.config,
    required this.logs,
    required this.currentDate,
    required this.message,
  });

  @override
  List<Object?> get props => [config, logs, currentDate, message];
}
