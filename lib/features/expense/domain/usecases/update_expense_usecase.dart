import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class UpdateExpenseUseCase {
  UpdateExpenseUseCase(this._repository);
  final ExpenseRepository _repository;

  Future<ExpenseEntity> call({
    required String flatId,
    required String expenseId,
    double? amount,
    String? description,
    String? date,
  }) =>
      _repository.updateExpense(
        flatId: flatId,
        expenseId: expenseId,
        amount: amount,
        description: description,
        date: date,
      );
}
