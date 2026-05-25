import '../entities/meal_log_entity.dart';
import '../repositories/meal_repository.dart';

class ManagerEditMealLogUseCase {
  ManagerEditMealLogUseCase(this._repo);
  final MealRepository _repo;
  Future<MealLogEntity> call(
          String flatId, String memberId, Map<String, dynamic> body) =>
      _repo.managerEditMealLog(flatId, memberId, body);
}
