import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_summary_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl({required ExpenseRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final ExpenseRemoteDataSource _dataSource;

  @override
  Future<Map<String, dynamic>> getExpenses(
    String flatId, {
    String? category,
    bool? isApproved,
    int? month,
    int? year,
    int page = 1,
    int limit = 20,
  }) =>
      _dataSource.getExpenses(
        flatId,
        category: category,
        isApproved: isApproved,
        month: month,
        year: year,
        page: page,
        limit: limit,
      );

  @override
  Future<ExpenseSummaryEntity> getExpenseSummary(
          String flatId, int month, int year) =>
      _dataSource.getExpenseSummary(flatId, month, year);

  @override
  Future<ExpenseEntity> getExpenseDetail(String flatId, String expenseId) =>
      _dataSource.getExpenseDetail(flatId, expenseId);

  @override
  Future<ExpenseEntity> recordExpense({
    required String flatId,
    required double amount,
    required String category,
    String? description,
    String? date,
  }) =>
      _dataSource.recordExpense(
        flatId: flatId,
        amount: amount,
        category: category,
        description: description,
        date: date,
      );

  @override
  Future<Map<String, dynamic>> approveExpense(
          String flatId, String expenseId) =>
      _dataSource.approveExpense(flatId, expenseId);

  @override
  Future<ExpenseEntity> updateExpense({
    required String flatId,
    required String expenseId,
    double? amount,
    String? description,
    String? date,
  }) =>
      _dataSource.updateExpense(
        flatId: flatId,
        expenseId: expenseId,
        amount: amount,
        description: description,
        date: date,
      );

  @override
  Future<void> deleteExpense(String flatId, String expenseId) =>
      _dataSource.deleteExpense(flatId, expenseId);
}
