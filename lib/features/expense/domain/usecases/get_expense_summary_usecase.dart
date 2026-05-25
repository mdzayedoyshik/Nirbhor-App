import '../entities/expense_summary_entity.dart';
import '../repositories/expense_repository.dart';

class GetExpenseSummaryUseCase {
  GetExpenseSummaryUseCase(this._repository);
  final ExpenseRepository _repository;

  Future<ExpenseSummaryEntity> call(String flatId, int month, int year) =>
      _repository.getExpenseSummary(flatId, month, year);
}
