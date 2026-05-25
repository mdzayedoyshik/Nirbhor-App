import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/expense_model.dart';
import '../models/expense_summary_model.dart';

class ExpenseRemoteDataSource {
  ExpenseRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getExpenses(
    String flatId, {
    String? category,
    bool? isApproved,
    int? month,
    int? year,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      'category': ?category,
      if (month != null) 'month': '$month',
      if (year != null) 'year': '$year',
      if (isApproved != null) 'is_approved': '$isApproved',
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final endpoint = '${ApiEndpoints.flatExpenses(flatId)}?$query';
    final response = await _apiClient.get(endpoint, auth: true);
    final data = response['data'] as Map<String, dynamic>;
    final expenses = (data['expenses'] as List)
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = data['pagination'] as Map<String, dynamic>;
    return {'expenses': expenses, 'pagination': pagination};
  }

  Future<ExpenseSummaryModel> getExpenseSummary(
      String flatId, int month, int year) async {
    final endpoint =
        '${ApiEndpoints.flatExpensesSummary(flatId)}?month=$month&year=$year';
    final response = await _apiClient.get(endpoint, auth: true);
    return ExpenseSummaryModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  Future<ExpenseModel> getExpenseDetail(
      String flatId, String expenseId) async {
    final response = await _apiClient.get(
        ApiEndpoints.flatExpense(flatId, expenseId),
        auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return ExpenseModel.fromJson(data['expense'] as Map<String, dynamic>);
  }

  Future<ExpenseModel> recordExpense({
    required String flatId,
    required double amount,
    required String category,
    String? description,
    String? date,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'expense_category': category,
      'description': ?description,
      'date': ?date,
    };
    final response = await _apiClient.post(
        ApiEndpoints.flatExpenses(flatId), body,
        auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return ExpenseModel.fromJson(data['expense'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> approveExpense(
      String flatId, String expenseId) async {
    final response = await _apiClient.post(
        ApiEndpoints.flatExpenseApprove(flatId, expenseId), {},
        auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return {
      'expense': ExpenseModel.fromJson(
          data['expense'] as Map<String, dynamic>),
      'deduction_result': data['deduction_result'],
    };
  }

  Future<ExpenseModel> updateExpense({
    required String flatId,
    required String expenseId,
    double? amount,
    String? description,
    String? date,
  }) async {
    final body = <String, dynamic>{
      'amount': ?amount,
      'description': ?description,
      'date': ?date,
    };
    final response = await _apiClient.put(
        ApiEndpoints.flatExpense(flatId, expenseId), body,
        auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return ExpenseModel.fromJson(data['expense'] as Map<String, dynamic>);
  }

  Future<void> deleteExpense(String flatId, String expenseId) =>
      _apiClient.delete(
          ApiEndpoints.flatExpense(flatId, expenseId),
          auth: true);
}
