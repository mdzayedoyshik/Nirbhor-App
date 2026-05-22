import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class GetExpenseDetailUseCase {
  GetExpenseDetailUseCase(this._repository);
  final ExpenseRepository _repository;

  Future<ExpenseEntity> call(String flatId, String expenseId) =>
      _repository.getExpenseDetail(flatId, expenseId);
}
