import '../repositories/meal_repository.dart';

class UpdateMealPreferencesUseCase {
  UpdateMealPreferencesUseCase(this._repo);
  final MealRepository _repo;
  Future<void> call(String flatId, String memberId,
          List<Map<String, dynamic>> preferences) =>
      _repo.updateMealPreferences(flatId, memberId, preferences);
}
