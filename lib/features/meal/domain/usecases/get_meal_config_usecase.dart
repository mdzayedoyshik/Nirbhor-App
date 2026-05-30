import '../entities/meal_config_entity.dart';
import '../repositories/meal_repository.dart';

class GetMealConfigUseCase {
  GetMealConfigUseCase(this._repo);
  final MealRepository _repo;
  Future<MealConfigEntity> call(String flatId) => _repo.getMealConfig(flatId);
}
