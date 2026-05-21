import 'package:equatable/equatable.dart';

import '../../domain/entities/fixed_expense_entity.dart';

enum FixedExpensesAction { add, update, delete, redistribute }

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

class FixedExpensesLoaded extends FixedExpensesState {
  final List<FixedExpenseEntity> expenses;

  const FixedExpensesLoaded(this.expenses);

  double get total => expenses.fold(0, (sum, e) => sum + e.amount);

  @override
  List<Object?> get props => [expenses];
}

/// An action is in progress; list stays visible.
class FixedExpensesActionInProgress extends FixedExpensesState {
  final List<FixedExpenseEntity> expenses;

  const FixedExpensesActionInProgress(this.expenses);

  double get total => expenses.fold(0, (sum, e) => sum + e.amount);

  @override
  List<Object?> get props => [expenses];
}

/// Action succeeded — ephemeral; bloc immediately emits FixedExpensesLoaded.
/// isFormAction = true for add/update (form listener pops sheet + snackbar).
/// isFormAction = false for delete/redistribute (page listener shows snackbar).
class FixedExpensesActionSuccess extends FixedExpensesState {
  final List<FixedExpenseEntity> expenses;
  final String message;
  final FixedExpensesAction action;

  const FixedExpensesActionSuccess({
    required this.expenses,
    required this.message,
    required this.action,
  });

  bool get isFormAction =>
      action == FixedExpensesAction.add || action == FixedExpensesAction.update;

  double get total => expenses.fold(0, (sum, e) => sum + e.amount);

  @override
  List<Object?> get props => [expenses, message, action];
}

/// An action failed — list retained; listener shows snackbar.
class FixedExpensesActionError extends FixedExpensesState {
  final List<FixedExpenseEntity> expenses;
  final String message;

  const FixedExpensesActionError({
    required this.expenses,
    required this.message,
  });

  double get total => expenses.fold(0, (sum, e) => sum + e.amount);

  @override
  List<Object?> get props => [expenses, message];
}

/// Initial load failed — show retry screen.
class FixedExpensesLoadError extends FixedExpensesState {
  final String message;

  const FixedExpensesLoadError(this.message);

  @override
  List<Object?> get props => [message];
}
