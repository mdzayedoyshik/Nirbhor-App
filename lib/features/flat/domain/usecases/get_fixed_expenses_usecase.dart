import '../entities/fixed_expense_entity.dart';
import '../repositories/flat_repository.dart';

class GetFixedExpensesUseCase {
  final FlatRepository _repository;
  GetFixedExpensesUseCase(this._repository);

  Future<List<FixedExpenseEntity>> call(String flatId) =>
      _repository.getFixedExpenses(flatId);
}
