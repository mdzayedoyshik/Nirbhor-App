import 'package:equatable/equatable.dart';

import '../../domain/entities/meal_pref_day_entity.dart';

abstract class MealPrefsState extends Equatable {
  const MealPrefsState();
  @override
  List<Object?> get props => [];
}

class MealPrefsInitial extends MealPrefsState {
  const MealPrefsInitial();
}

class MealPrefsLoading extends MealPrefsState {
  const MealPrefsLoading();
}

class MealPrefsLoaded extends MealPrefsState {
  final List<MealPrefDayEntity> prefs;
  final bool isDirty;

  const MealPrefsLoaded(this.prefs, {this.isDirty = false});

  @override
  List<Object?> get props => [prefs, isDirty];
}

class MealPrefsSaving extends MealPrefsState {
  final List<MealPrefDayEntity> prefs;
  const MealPrefsSaving(this.prefs);
  @override
  List<Object?> get props => [prefs];
}

class MealPrefsSaveSuccess extends MealPrefsState {
  final List<MealPrefDayEntity> prefs;
  const MealPrefsSaveSuccess(this.prefs);
  @override
  List<Object?> get props => [prefs];
}

class MealPrefsError extends MealPrefsState {
  final String message;
  final List<MealPrefDayEntity>? prefs;

  const MealPrefsError(this.message, {this.prefs});

  @override
  List<Object?> get props => [message, prefs];
}
