import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../expense/data/models/expense_model.dart';
import '../../domain/entities/month_close_status_entity.dart';
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

  Future<MonthCloseStatusEntity> getMonthCloseStatus(String flatId) async {
    final response = await _apiClient.get(
      ApiEndpoints.flatMonthlySummaryCloseStatus(flatId),
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    final status = data['status'] as String;

    if (status == 'none') {
      return const MonthCloseStatusEntity(status: 'none');
    }

    final blockers = data['blockers'] as Map<String, dynamic>? ?? {};
    final expenseList = (blockers['unapproved_expenses'] as List? ?? [])
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return MonthCloseStatusEntity(
      status: status,
      month: (data['month'] as num).toInt(),
      year: (data['year'] as num).toInt(),
      monthName: data['month_name'] as String?,
      unapprovedExpenses: expenseList,
    );
  }
}
