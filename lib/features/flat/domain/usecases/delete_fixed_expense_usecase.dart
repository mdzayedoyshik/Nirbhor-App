import '../repositories/flat_repository.dart';

class DeleteFixedExpenseUseCase {
  final FlatRepository _repository;
  DeleteFixedExpenseUseCase(this._repository);

  Future<void> call({required String flatId, required String expenseId}) =>
      _repository.deleteFixedExpense(flatId: flatId, expenseId: expenseId);
}
