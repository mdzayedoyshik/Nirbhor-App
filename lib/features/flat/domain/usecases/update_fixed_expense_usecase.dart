import '../entities/fixed_expense_entity.dart';
import '../repositories/flat_repository.dart';

class UpdateFixedExpenseUseCase {
  final FlatRepository _repository;
  UpdateFixedExpenseUseCase(this._repository);

  Future<FixedExpenseEntity> call({
    required String flatId,
    required String expenseId,
    String? expenseType,
    double? amount,
  }) => _repository.updateFixedExpense(
    flatId: flatId,
    expenseId: expenseId,
    expenseType: expenseType,
    amount: amount,
  );
}
