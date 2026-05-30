import '../entities/daily_meal_logs_entity.dart';
import '../repositories/meal_repository.dart';

class GetDailyMealLogsUseCase {
  GetDailyMealLogsUseCase(this._repo);
  final MealRepository _repo;
  Future<DailyMealLogsEntity> call(String flatId, String date) =>
      _repo.getDailyMealLogs(flatId, date);
}
