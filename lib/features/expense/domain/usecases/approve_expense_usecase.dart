import '../repositories/expense_repository.dart';

class ApproveExpenseUseCase {
  ApproveExpenseUseCase(this._repository);
  final ExpenseRepository _repository;

  Future<Map<String, dynamic>> call(String flatId, String expenseId) =>
      _repository.approveExpense(flatId, expenseId);
}
