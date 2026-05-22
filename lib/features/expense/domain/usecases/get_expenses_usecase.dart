import '../repositories/expense_repository.dart';

class GetExpensesUseCase {
  GetExpensesUseCase(this._repository);
  final ExpenseRepository _repository;

  Future<Map<String, dynamic>> call(
    String flatId, {
    String? category,
    bool? isApproved,
    int? month,
    int? year,
    int page = 1,
    int limit = 20,
  }) =>
      _repository.getExpenses(
        flatId,
        category: category,
        isApproved: isApproved,
        month: month,
        year: year,
        page: page,
        limit: limit,
      );
}
