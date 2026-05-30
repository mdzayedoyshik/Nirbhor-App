import '../../domain/entities/daily_meal_logs_entity.dart';
import '../../domain/entities/meal_config_entity.dart';
import '../../domain/entities/meal_log_entity.dart';
import '../../domain/entities/meal_pool_entity.dart';
import '../../domain/entities/meal_pref_day_entity.dart';
import '../../domain/entities/meal_toggle_entity.dart';
import '../../domain/repositories/meal_repository.dart';
import '../datasources/meal_remote_datasource.dart';

class MealRepositoryImpl implements MealRepository {
  MealRepositoryImpl({required MealRemoteDataSource dataSource})
      : _ds = dataSource;

  final MealRemoteDataSource _ds;

  @override
  Future<MealConfigEntity> getMealConfig(String flatId) =>
      _ds.getMealConfig(flatId);

  @override
  Future<MealConfigEntity> updateMealConfig(
          String flatId, Map<String, dynamic> data) =>
      _ds.updateMealConfig(flatId, data);

  @override
  Future<MealToggleEntity> getMealToggle(String flatId, String date) =>
      _ds.getMealToggle(flatId, date);

  @override
  Future<MealToggleEntity> setMealToggle(
          String flatId, Map<String, dynamic> data) =>
      _ds.setMealToggle(flatId, data);

  @override
  Future<List<MealPrefDayEntity>> getMealPreferences(
          String flatId, String memberId) =>
      _ds.getMealPreferences(flatId, memberId);

  @override
  Future<void> updateMealPreferences(String flatId, String memberId,
          List<Map<String, dynamic>> preferences) =>
      _ds.updateMealPreferences(flatId, memberId, preferences);

  @override
  Future<DailyMealLogsEntity> getDailyMealLogs(String flatId, String date) =>
      _ds.getDailyMealLogs(flatId, date);

  @override
  Future<MealLogEntity> updateOwnMealLog(
          String flatId, Map<String, dynamic> body) =>
      _ds.updateOwnMealLog(flatId, body);

  @override
  Future<MealLogEntity> managerEditMealLog(
          String flatId, String memberId, Map<String, dynamic> body) =>
      _ds.managerEditMealLog(flatId, memberId, body);

  @override
  Future<MealPoolEntity> getMealPool(String flatId, int month, int year) =>
      _ds.getMealPool(flatId, month, year);
}
