part of 'fixed_expenses_cubit.dart';

abstract class FixedExpensesState extends Equatable {
  const FixedExpensesState();
  @override
  List<Object?> get props => [];
}

class FixedExpensesInitial extends FixedExpensesState {
  const FixedExpensesInitial();
}

class FixedExpensesLoading extends FixedExpensesState {
  const FixedExpensesLoading();
}

/// Form submit / delete in progress
class FixedExpensesFormLoading extends FixedExpensesState {
  const FixedExpensesFormLoading();
}

class FixedExpensesLoaded extends FixedExpensesState {
  final List<FixedExpenseEntity> expenses;

  const FixedExpensesLoaded(this.expenses);

  double get total => expenses.fold(0, (sum, e) => sum + e.amount);

  @override
  List<Object?> get props => [expenses];
}

class FixedExpensesError extends FixedExpensesState {
  final String message;
  const FixedExpensesError(this.message);
  @override
  List<Object?> get props => [message];
}
