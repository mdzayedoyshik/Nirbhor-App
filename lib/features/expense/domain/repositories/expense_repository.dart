import '../entities/expense_entity.dart';
import '../entities/expense_summary_entity.dart';

abstract class ExpenseRepository {
  Future<Map<String, dynamic>> getExpenses(
    String flatId, {
    String? category,
    bool? isApproved,
    int? month,
    int? year,
    int page,
    int limit,
  });

  Future<ExpenseSummaryEntity> getExpenseSummary(
      String flatId, int month, int year);

  Future<ExpenseEntity> getExpenseDetail(String flatId, String expenseId);

  Future<ExpenseEntity> recordExpense({
    required String flatId,
    required double amount,
    required String category,
    String? description,
    String? date,
  });

  Future<Map<String, dynamic>> approveExpense(
      String flatId, String expenseId);

  Future<ExpenseEntity> updateExpense({
    required String flatId,
    required String expenseId,
    double? amount,
    String? description,
    String? date,
  });

  Future<void> deleteExpense(String flatId, String expenseId);
}
