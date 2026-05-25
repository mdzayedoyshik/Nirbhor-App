import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/daily_meal_logs_entity.dart';
import '../../domain/entities/meal_log_entity.dart';
import '../../domain/entities/meal_pool_entity.dart';
import '../../domain/entities/meal_pref_day_entity.dart';
import '../../domain/entities/meal_toggle_entity.dart';
import '../models/daily_meal_logs_model.dart';
import '../models/meal_config_model.dart';
import '../models/meal_log_model.dart';
import '../models/meal_pref_day_model.dart';
import '../models/meal_pool_model.dart';
import '../models/meal_toggle_model.dart';

class MealRemoteDataSource {
  MealRemoteDataSource({required ApiClient apiClient})
      : _api = apiClient;

  final ApiClient _api;

  // ── Config ──────────────────────────────────────────────────────────────────

  Future<MealConfigModel> getMealConfig(String flatId) async {
    final r = await _api.get(ApiEndpoints.mealConfig(flatId), auth: true);
    return MealConfigModel.fromJson(r['data']['config'] as Map<String, dynamic>);
  }

  Future<MealConfigModel> updateMealConfig(
      String flatId, Map<String, dynamic> data) async {
    final r = await _api.put(ApiEndpoints.mealConfig(flatId), data, auth: true);
    return MealConfigModel.fromJson(r['data']['config'] as Map<String, dynamic>);
  }

  // ── Toggles ─────────────────────────────────────────────────────────────────

  Future<MealToggleModel> getMealToggle(String flatId, String date) async {
    final r = await _api.get(
        '${ApiEndpoints.mealToggles(flatId)}?date=$date',
        auth: true);
    return MealToggleModel.fromJson(r['data'] as Map<String, dynamic>);
  }

  Future<MealToggleEntity> setMealToggle(
      String flatId, Map<String, dynamic> data) async {
    final r =
        await _api.post(ApiEndpoints.mealToggles(flatId), data, auth: true);
    return MealToggleModel.fromJson(r['data'] as Map<String, dynamic>);
  }

  // ── Preferences ─────────────────────────────────────────────────────────────

  Future<List<MealPrefDayEntity>> getMealPreferences(
      String flatId, String memberId) async {
    final r = await _api.get(
        ApiEndpoints.mealPreferences(flatId, memberId),
        auth: true);
    final data = r['data'] as Map<String, dynamic>;
    return (data['preferences'] as List)
        .map((e) => MealPrefDayModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateMealPreferences(String flatId, String memberId,
      List<Map<String, dynamic>> preferences) async {
    await _api.put(
      ApiEndpoints.mealPreferences(flatId, memberId),
      {'preferences': preferences},
      auth: true,
    );
  }

  // ── Daily logs ──────────────────────────────────────────────────────────────

  Future<DailyMealLogsEntity> getDailyMealLogs(
      String flatId, String date) async {
    final r = await _api.get(
        '${ApiEndpoints.mealLogs(flatId)}?date=$date',
        auth: true);
    return DailyMealLogsModel.fromJson(r['data'] as Map<String, dynamic>);
  }

  Future<MealLogEntity> updateOwnMealLog(
      String flatId, Map<String, dynamic> body) async {
    final r =
        await _api.patch(ApiEndpoints.myMealLog(flatId), body, auth: true);
    return MealLogModel.fromJson(r['data']['log'] as Map<String, dynamic>);
  }

  Future<MealLogEntity> managerEditMealLog(
      String flatId, String memberId, Map<String, dynamic> body) async {
    final r = await _api.patch(
        ApiEndpoints.mealLogForMember(flatId, memberId), body,
        auth: true);
    return MealLogModel.fromJson(r['data']['log'] as Map<String, dynamic>);
  }

  // ── Pool ────────────────────────────────────────────────────────────────────

  Future<MealPoolEntity> getMealPool(
      String flatId, int month, int year) async {
    final r = await _api.get(
        '${ApiEndpoints.mealPool(flatId)}?month=$month&year=$year',
        auth: true);
    return MealPoolModel.fromJson(r['data'] as Map<String, dynamic>);
  }
}
