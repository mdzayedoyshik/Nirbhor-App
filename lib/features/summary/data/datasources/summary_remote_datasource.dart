import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/close_preview_model.dart';
import '../models/closed_month_model.dart';
import '../models/month_summary_model.dart';

class SummaryRemoteDataSource {
  SummaryRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;
  final ApiClient _apiClient;

  Future<MonthSummaryModel> getMonthlySummary(
      String flatId, int month, int year) async {
    final endpoint =
        '${ApiEndpoints.flatMonthlySummary(flatId)}?month=$month&year=$year';
    final response = await _apiClient.get(endpoint, auth: true);
    return MonthSummaryModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ClosePreviewModel> getClosePreview(String flatId) async {
    final response = await _apiClient.get(
      ApiEndpoints.flatMonthlySummaryPreview(flatId),
      auth: true,
    );
    return ClosePreviewModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  Future<void> closeMonth(
      String flatId, int month, int year, bool force) async {
    await _apiClient.post(
      ApiEndpoints.flatMonthlySummaryClose(flatId),
      {'month': month, 'year': year, 'force': force},
      auth: true,
    );
  }

  Future<List<ClosedMonthModel>> getClosedMonths(String flatId) async {
    final response = await _apiClient.get(
      ApiEndpoints.flatMonthlySummaries(flatId),
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['closed_months'] as List)
        .map((e) =>
            ClosedMonthModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
