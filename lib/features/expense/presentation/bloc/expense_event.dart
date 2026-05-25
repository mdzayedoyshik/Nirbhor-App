import 'package:equatable/equatable.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();
}

class ExpensesLoadRequested extends ExpenseEvent {
  const ExpensesLoadRequested(
    this.flatId, {
    this.month,
    this.year,
    this.category,
    this.isApproved,
    this.page = 1,
  });

  final String flatId;
  final int? month;
  final int? year;
  final String? category;
  final bool? isApproved;
  final int page;

  @override
  List<Object?> get props => [flatId, month, year, category, isApproved, page];
}

class ExpensesLoadMoreRequested extends ExpenseEvent {
  const ExpensesLoadMoreRequested(
    this.flatId, {
    this.month,
    this.year,
    this.category,
    this.isApproved,
    required this.nextPage,
  });

  final String flatId;
  final int? month;
  final int? year;
  final String? category;
  final bool? isApproved;
  final int nextPage;

  @override
  List<Object?> get props =>
      [flatId, month, year, category, isApproved, nextPage];
}

class ExpenseSummaryRequested extends ExpenseEvent {
  const ExpenseSummaryRequested(this.flatId, this.month, this.year);
  final String flatId;
  final int month;
  final int year;
  @override
  List<Object?> get props => [flatId, month, year];
}

class ExpenseDetailRequested extends ExpenseEvent {
  const ExpenseDetailRequested(this.flatId, this.expenseId);
  final String flatId;
  final String expenseId;
  @override
  List<Object?> get props => [flatId, expenseId];
}

class ExpenseRecordRequested extends ExpenseEvent {
  const ExpenseRecordRequested({
    required this.flatId,
    required this.amount,
    required this.category,
    this.description,
    this.date,
  });
  final String flatId;
  final double amount;
  final String category;
  final String? description;
  final String? date;
  @override
  List<Object?> get props => [flatId, amount, category, description, date];
}

class ExpenseApproveRequested extends ExpenseEvent {
  const ExpenseApproveRequested(this.flatId, this.expenseId);
  final String flatId;
  final String expenseId;
  @override
  List<Object?> get props => [flatId, expenseId];
}

class ExpenseUpdateRequested extends ExpenseEvent {
  const ExpenseUpdateRequested({
    required this.flatId,
    required this.expenseId,
    this.amount,
    this.description,
    this.date,
  });
  final String flatId;
  final String expenseId;
  final double? amount;
  final String? description;
  final String? date;
  @override
  List<Object?> get props => [flatId, expenseId, amount, description, date];
}

class ExpenseDeleteRequested extends ExpenseEvent {
  const ExpenseDeleteRequested(this.flatId, this.expenseId);
  final String flatId;
  final String expenseId;
  @override
  List<Object?> get props => [flatId, expenseId];
}
