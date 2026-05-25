import '../entities/meal_config_entity.dart';
import '../repositories/meal_repository.dart';

class UpdateMealConfigUseCase {
  UpdateMealConfigUseCase(this._repo);
  final MealRepository _repo;
  Future<MealConfigEntity> call(String flatId, Map<String, dynamic> data) =>
      _repo.updateMealConfig(flatId, data);
}
