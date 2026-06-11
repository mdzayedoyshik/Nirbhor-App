import '../../../../core/cache/cache_service.dart';
import '../../../../core/cache/cacheable.dart';
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
  MealRemoteDataSource({required ApiClient apiClient, required CacheService cache})
      : _api = apiClient,
        _cache = cache;

  final ApiClient _api;
  final CacheService _cache;

  // ── Config ──────────────────────────────────────────────────────────────────

  Future<MealConfigModel> getMealConfig(String flatId) => cacheable(
        cache: _cache,
        key: 'meal_config:$flatId',
        fetchRaw: () => _api.get(ApiEndpoints.mealConfig(flatId), auth: true),
        parse: (json) => MealConfigModel.fromJson(
            json['data']['config'] as Map<String, dynamic>),
      );

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

  Future<DailyMealLogsEntity> getDailyMealLogs(String flatId, String date) =>
      cacheable(
        cache: _cache,
        key: 'meal_logs:$flatId:$date',
        fetchRaw: () =>
            _api.get('${ApiEndpoints.mealLogs(flatId)}?date=$date', auth: true),
        parse: (json) =>
            DailyMealLogsModel.fromJson(json['data'] as Map<String, dynamic>),
      );

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

  Future<MealPoolEntity> getMealPool(String flatId, int month, int year) =>
      cacheable(
        cache: _cache,
        key: 'meal_pool:$flatId:$month:$year',
        fetchRaw: () => _api.get(
            '${ApiEndpoints.mealPool(flatId)}?month=$month&year=$year',
            auth: true),
        parse: (json) =>
            MealPoolModel.fromJson(json['data'] as Map<String, dynamic>),
      );

  Future<Map<String, dynamic>> getMemberMonthlyLogs(
      String flatId, String memberId, int month, int year) async {
    final r = await _api.get(
        '${ApiEndpoints.memberMealLogs(flatId, memberId)}?month=$month&year=$year',
        auth: true);
    return r['data'] as Map<String, dynamic>;
  }
}
