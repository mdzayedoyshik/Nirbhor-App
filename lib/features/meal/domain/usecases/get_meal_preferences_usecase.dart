import '../entities/meal_pref_day_entity.dart';
import '../repositories/meal_repository.dart';

class GetMealPreferencesUseCase {
  GetMealPreferencesUseCase(this._repo);
  final MealRepository _repo;
  Future<List<MealPrefDayEntity>> call(String flatId, String memberId) =>
      _repo.getMealPreferences(flatId, memberId);
}
