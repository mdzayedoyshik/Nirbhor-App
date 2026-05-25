import '../entities/meal_toggle_entity.dart';
import '../repositories/meal_repository.dart';

class SetMealToggleUseCase {
  SetMealToggleUseCase(this._repo);
  final MealRepository _repo;
  Future<MealToggleEntity> call(String flatId, Map<String, dynamic> data) =>
      _repo.setMealToggle(flatId, data);
}
