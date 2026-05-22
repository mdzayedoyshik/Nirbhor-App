import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class RecordExpenseUseCase {
  RecordExpenseUseCase(this._repository);
  final ExpenseRepository _repository;

  Future<ExpenseEntity> call({
    required String flatId,
    required double amount,
    required String category,
    String? description,
    String? date,
  }) =>
      _repository.recordExpense(
        flatId: flatId,
        amount: amount,
        category: category,
        description: description,
        date: date,
      );
}
