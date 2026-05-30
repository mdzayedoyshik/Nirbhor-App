import '../entities/daily_meal_logs_entity.dart';
import '../entities/meal_config_entity.dart';
import '../entities/meal_log_entity.dart';
import '../entities/meal_pool_entity.dart';
import '../entities/meal_pref_day_entity.dart';
import '../entities/meal_toggle_entity.dart';

abstract class MealRepository {
  Future<MealConfigEntity> getMealConfig(String flatId);
  Future<MealConfigEntity> updateMealConfig(
      String flatId, Map<String, dynamic> data);

  Future<MealToggleEntity> getMealToggle(String flatId, String date);
  Future<MealToggleEntity> setMealToggle(
      String flatId, Map<String, dynamic> data);

  Future<List<MealPrefDayEntity>> getMealPreferences(
      String flatId, String memberId);
  Future<void> updateMealPreferences(
      String flatId, String memberId, List<Map<String, dynamic>> preferences);

  Future<DailyMealLogsEntity> getDailyMealLogs(String flatId, String date);
  Future<MealLogEntity> updateOwnMealLog(
      String flatId, Map<String, dynamic> body);
  Future<MealLogEntity> managerEditMealLog(
      String flatId, String memberId, Map<String, dynamic> body);

  Future<MealPoolEntity> getMealPool(String flatId, int month, int year);
}
