import '../entities/meal_log_entity.dart';
import '../repositories/meal_repository.dart';

class UpdateOwnMealLogUseCase {
  UpdateOwnMealLogUseCase(this._repo);
  final MealRepository _repo;
  Future<MealLogEntity> call(String flatId, Map<String, dynamic> body) =>
      _repo.updateOwnMealLog(flatId, body);
}
