import '../entities/meal_pool_entity.dart';
import '../repositories/meal_repository.dart';

class GetMealPoolUseCase {
  GetMealPoolUseCase(this._repo);
  final MealRepository _repo;
  Future<MealPoolEntity> call(String flatId, int month, int year) =>
      _repo.getMealPool(flatId, month, year);
}
