import '../entities/fixed_expense_entity.dart';
import '../repositories/flat_repository.dart';

class AddFixedExpenseUseCase {
  final FlatRepository _repository;
  AddFixedExpenseUseCase(this._repository);

  Future<FixedExpenseEntity> call({
    required String flatId,
    required String expenseType,
    required double amount,
  }) => _repository.addFixedExpense(
    flatId: flatId,
    expenseType: expenseType,
    amount: amount,
  );
}
