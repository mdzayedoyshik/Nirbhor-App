import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/meal_pref_day_entity.dart';
import '../../domain/usecases/get_meal_preferences_usecase.dart';
import '../../domain/usecases/update_meal_preferences_usecase.dart';
import 'meal_prefs_event.dart';
import 'meal_prefs_state.dart';

export 'meal_prefs_event.dart';
export 'meal_prefs_state.dart';

class MealPrefsBloc extends Bloc<MealPrefsEvent, MealPrefsState> {
  final GetMealPreferencesUseCase _getPrefs;
  final UpdateMealPreferencesUseCase _updatePrefs;

  MealPrefsBloc({
    required GetMealPreferencesUseCase getPrefs,
    required UpdateMealPreferencesUseCase updatePrefs,
  })  : _getPrefs = getPrefs,
        _updatePrefs = updatePrefs,
        super(const MealPrefsInitial()) {
    on<MealPrefsLoadRequested>(_onLoad);
    on<MealPrefsDayToggled>(_onToggle);
    on<MealPrefsSaveRequested>(_onSave);
  }

  Future<void> _onLoad(
    MealPrefsLoadRequested event,
    Emitter<MealPrefsState> emit,
  ) async {
    emit(const MealPrefsLoading());
    try {
      final prefs = await _getPrefs(event.flatId, event.memberId);
      emit(MealPrefsLoaded(prefs));
    } catch (e) {
      emit(MealPrefsError(_msg(e)));
    }
  }

  void _onToggle(
    MealPrefsDayToggled event,
    Emitter<MealPrefsState> emit,
  ) {
    final current = _currentPrefs;
    if (current == null) return;
    final updated = current.map((p) {
      if (p.dayOfWeek != event.dayOfWeek) return p;
      return p.copyWith(
        breakfast: event.shift == 'breakfast' ? !p.breakfast : null,
        lunch: event.shift == 'lunch' ? !p.lunch : null,
        dinner: event.shift == 'dinner' ? !p.dinner : null,
      );
    }).toList();
    emit(MealPrefsLoaded(updated, isDirty: true));
  }

  Future<void> _onSave(
    MealPrefsSaveRequested event,
    Emitter<MealPrefsState> emit,
  ) async {
    final current = _currentPrefs;
    if (current == null) return;
    emit(MealPrefsSaving(current));
    try {
      final payload = current
          .map((p) => {
                'day_of_week': p.dayOfWeek,
                'breakfast': p.breakfast,
                'lunch': p.lunch,
                'dinner': p.dinner,
              })
          .toList();
      await _updatePrefs(event.flatId, event.memberId, payload);
      emit(MealPrefsSaveSuccess(current));
      emit(MealPrefsLoaded(current));
    } catch (e) {
      emit(MealPrefsError(_msg(e), prefs: current));
      emit(MealPrefsLoaded(current, isDirty: true));
    }
  }

  List<MealPrefDayEntity>? get _currentPrefs {
    final s = state;
    if (s is MealPrefsLoaded) return s.prefs;
    if (s is MealPrefsSaving) return s.prefs;
    if (s is MealPrefsSaveSuccess) return s.prefs;
    if (s is MealPrefsError) return s.prefs;
    return null;
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
