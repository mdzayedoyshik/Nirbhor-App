import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/daily_meal_logs_entity.dart';
import '../../domain/entities/meal_config_entity.dart';
import '../../domain/usecases/get_daily_meal_logs_usecase.dart';
import '../../domain/usecases/get_meal_config_usecase.dart';
import '../../domain/usecases/manager_edit_meal_log_usecase.dart';
import '../../domain/usecases/set_meal_toggle_usecase.dart';
import '../../domain/usecases/update_meal_config_usecase.dart';
import '../../domain/usecases/update_own_meal_log_usecase.dart';
import 'meal_event.dart';
import 'meal_state.dart';

export 'meal_event.dart';
export 'meal_state.dart';

class MealBloc extends Bloc<MealEvent, MealState> {
  final GetMealConfigUseCase _getConfig;
  final UpdateMealConfigUseCase _updateConfig;
  final GetDailyMealLogsUseCase _getDailyLogs;
  final UpdateOwnMealLogUseCase _updateOwnLog;
  final ManagerEditMealLogUseCase _managerEdit;
  final SetMealToggleUseCase _setToggle;

  MealBloc({
    required GetMealConfigUseCase getConfig,
    required UpdateMealConfigUseCase updateConfig,
    required GetDailyMealLogsUseCase getDailyLogs,
    required UpdateOwnMealLogUseCase updateOwnLog,
    required ManagerEditMealLogUseCase managerEdit,
    required SetMealToggleUseCase setToggle,
  })  : _getConfig = getConfig,
        _updateConfig = updateConfig,
        _getDailyLogs = getDailyLogs,
        _updateOwnLog = updateOwnLog,
        _managerEdit = managerEdit,
        _setToggle = setToggle,
        super(const MealInitial()) {
    on<MealDailyLoadRequested>(_onLoad);
    on<MealDailyDateChanged>(_onDateChanged);
    on<MealSelfToggleRequested>(_onSelfToggle);
    on<MealManagerEditRequested>(_onManagerEdit);
    on<MealFlatToggleRequested>(_onFlatToggle);
    on<MealConfigUpdateRequested>(_onConfigUpdate);
  }

  Future<void> _onLoad(
    MealDailyLoadRequested event,
    Emitter<MealState> emit,
  ) async {
    emit(const MealLoading());
    try {
      final config = await _getConfig(event.flatId);
      final logs = await _getDailyLogs(event.flatId, event.date);
      emit(MealDailyLoaded(
        config: config,
        logs: logs,
        currentDate: event.date,
      ));
    } catch (e) {
      emit(MealLoadError(_msg(e)));
    }
  }

  Future<void> _onDateChanged(
    MealDailyDateChanged event,
    Emitter<MealState> emit,
  ) async {
    final current = _current;
    if (current == null) return;
    emit(MealActionInProgress(
      config: current.config,
      logs: current.logs,
      currentDate: current.currentDate,
    ));
    try {
      final logs = await _getDailyLogs(event.flatId, event.date);
      emit(MealDailyLoaded(
        config: current.config,
        logs: logs,
        currentDate: event.date,
      ));
    } catch (e) {
      emit(MealActionError(
        config: current.config,
        logs: current.logs,
        currentDate: current.currentDate,
        message: _msg(e),
      ));
      emit(MealDailyLoaded(
        config: current.config,
        logs: current.logs,
        currentDate: current.currentDate,
      ));
    }
  }

  Future<void> _onSelfToggle(
    MealSelfToggleRequested event,
    Emitter<MealState> emit,
  ) async {
    final current = _current;
    if (current == null) return;
    emit(MealActionInProgress(
      config: current.config,
      logs: current.logs,
      currentDate: current.currentDate,
    ));
    try {
      await _updateOwnLog(event.flatId, event.body);
      final logs = await _getDailyLogs(event.flatId, current.currentDate);
      emit(MealActionSuccess(
        config: current.config,
        logs: logs,
        currentDate: current.currentDate,
        message: 'Meal updated.',
      ));
      emit(MealDailyLoaded(
        config: current.config,
        logs: logs,
        currentDate: current.currentDate,
      ));
    } catch (e) {
      emit(MealActionError(
        config: current.config,
        logs: current.logs,
        currentDate: current.currentDate,
        message: _msg(e),
      ));
      emit(MealDailyLoaded(
        config: current.config,
        logs: current.logs,
        currentDate: current.currentDate,
      ));
    }
  }

  Future<void> _onManagerEdit(
    MealManagerEditRequested event,
    Emitter<MealState> emit,
  ) async {
    final current = _current;
    if (current == null) return;
    emit(MealActionInProgress(
      config: current.config,
      logs: current.logs,
      currentDate: current.currentDate,
    ));
    try {
      await _managerEdit(event.flatId, event.memberId, event.body);
      final logs = await _getDailyLogs(event.flatId, current.currentDate);
      emit(MealActionSuccess(
        config: current.config,
        logs: logs,
        currentDate: current.currentDate,
        message: 'Meal log updated.',
      ));
      emit(MealDailyLoaded(
        config: current.config,
        logs: logs,
        currentDate: current.currentDate,
      ));
    } catch (e) {
      emit(MealActionError(
        config: current.config,
        logs: current.logs,
        currentDate: current.currentDate,
        message: _msg(e),
      ));
      emit(MealDailyLoaded(
        config: current.config,
        logs: current.logs,
        currentDate: current.currentDate,
      ));
    }
  }

  Future<void> _onFlatToggle(
    MealFlatToggleRequested event,
    Emitter<MealState> emit,
  ) async {
    final current = _current;
    if (current == null) return;
    emit(MealActionInProgress(
      config: current.config,
      logs: current.logs,
      currentDate: current.currentDate,
    ));
    try {
      await _setToggle(event.flatId, event.body);
      final logs = await _getDailyLogs(event.flatId, current.currentDate);
      emit(MealActionSuccess(
        config: current.config,
        logs: logs,
        currentDate: current.currentDate,
        message: 'Flat meal toggle updated.',
      ));
      emit(MealDailyLoaded(
        config: current.config,
        logs: logs,
        currentDate: current.currentDate,
      ));
    } catch (e) {
      emit(MealActionError(
        config: current.config,
        logs: current.logs,
        currentDate: current.currentDate,
        message: _msg(e),
      ));
      emit(MealDailyLoaded(
        config: current.config,
        logs: current.logs,
        currentDate: current.currentDate,
      ));
    }
  }

  Future<void> _onConfigUpdate(
    MealConfigUpdateRequested event,
    Emitter<MealState> emit,
  ) async {
    final current = _current;
    if (current == null) return;
    emit(MealActionInProgress(
      config: current.config,
      logs: current.logs,
      currentDate: current.currentDate,
    ));
    try {
      final config = await _updateConfig(event.flatId, event.data);
      emit(MealActionSuccess(
        config: config,
        logs: current.logs,
        currentDate: current.currentDate,
        message: 'Meal settings saved.',
      ));
      emit(MealDailyLoaded(
        config: config,
        logs: current.logs,
        currentDate: current.currentDate,
      ));
    } catch (e) {
      emit(MealActionError(
        config: current.config,
        logs: current.logs,
        currentDate: current.currentDate,
        message: _msg(e),
      ));
      emit(MealDailyLoaded(
        config: current.config,
        logs: current.logs,
        currentDate: current.currentDate,
      ));
    }
  }

  ({
    MealConfigEntity config,
    DailyMealLogsEntity logs,
    String currentDate,
  })? get _current {
    final s = state;
    if (s is MealDailyLoaded) {
      return (config: s.config, logs: s.logs, currentDate: s.currentDate);
    }
    if (s is MealActionInProgress) {
      return (config: s.config, logs: s.logs, currentDate: s.currentDate);
    }
    if (s is MealActionError) {
      return (config: s.config, logs: s.logs, currentDate: s.currentDate);
    }
    if (s is MealActionSuccess) {
      return (config: s.config, logs: s.logs, currentDate: s.currentDate);
    }
    return null;
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
