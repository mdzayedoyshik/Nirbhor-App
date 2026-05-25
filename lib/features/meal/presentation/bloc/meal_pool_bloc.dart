import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/usecases/get_meal_pool_usecase.dart';
import 'meal_pool_event.dart';
import 'meal_pool_state.dart';

export 'meal_pool_event.dart';
export 'meal_pool_state.dart';

class MealPoolBloc extends Bloc<MealPoolEvent, MealPoolState> {
  final GetMealPoolUseCase _getPool;

  MealPoolBloc({required GetMealPoolUseCase getPool})
      : _getPool = getPool,
        super(const MealPoolInitial()) {
    on<MealPoolLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
    MealPoolLoadRequested event,
    Emitter<MealPoolState> emit,
  ) async {
    emit(const MealPoolLoading());
    try {
      final pool = await _getPool(event.flatId, event.month, event.year);
      emit(MealPoolLoaded(pool: pool, month: event.month, year: event.year));
    } catch (e) {
      emit(MealPoolError(_msg(e)));
    }
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
