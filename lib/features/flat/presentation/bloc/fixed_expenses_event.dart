import 'package:equatable/equatable.dart';

abstract class FixedExpensesEvent extends Equatable {
  const FixedExpensesEvent();
  @override
  List<Object?> get props => [];
}

class FixedExpensesLoadRequested extends FixedExpensesEvent {
  final String flatId;

  const FixedExpensesLoadRequested(this.flatId);

  @override
  List<Object?> get props => [flatId];
}

class FixedExpenseAddRequested extends FixedExpensesEvent {
  final String flatId;
  final String expenseType;
  final double amount;

  const FixedExpenseAddRequested({
    required this.flatId,
    required this.expenseType,
    required this.amount,
  });

  @override
  List<Object?> get props => [flatId, expenseType, amount];
}

class FixedExpenseUpdateRequested extends FixedExpensesEvent {
  final String flatId;
  final String expenseId;
  final String? expenseType;
  final double? amount;

  const FixedExpenseUpdateRequested({
    required this.flatId,
    required this.expenseId,
    this.expenseType,
    this.amount,
  });

  @override
  List<Object?> get props => [flatId, expenseId, expenseType, amount];
}

class FixedExpenseDeleteRequested extends FixedExpensesEvent {
  final String flatId;
  final String expenseId;

  const FixedExpenseDeleteRequested({
    required this.flatId,
    required this.expenseId,
  });

  @override
  List<Object?> get props => [flatId, expenseId];
}

class FixedExpensesRedistributeRequested extends FixedExpensesEvent {
  final String flatId;

  const FixedExpensesRedistributeRequested(this.flatId);

  @override
  List<Object?> get props => [flatId];
}
