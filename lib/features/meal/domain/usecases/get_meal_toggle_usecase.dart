import '../entities/meal_toggle_entity.dart';
import '../repositories/meal_repository.dart';

class GetMealToggleUseCase {
  GetMealToggleUseCase(this._repo);
  final MealRepository _repo;
  Future<MealToggleEntity> call(String flatId, String date) =>
      _repo.getMealToggle(flatId, date);
}
