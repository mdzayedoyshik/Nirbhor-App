import '../../domain/entities/expense_entity.dart';

class EditExpenseArgs {
  const EditExpenseArgs({
    required this.flatId,
    required this.expense,
  });

  final String flatId;
  final ExpenseEntity expense;
}
