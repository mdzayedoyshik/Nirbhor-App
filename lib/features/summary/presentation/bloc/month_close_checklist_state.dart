part of 'month_close_checklist_bloc.dart';

abstract class MonthCloseChecklistState extends Equatable {
  const MonthCloseChecklistState();
}

class MonthCloseChecklistInitial extends MonthCloseChecklistState {
  const MonthCloseChecklistInitial();
  @override
  List<Object?> get props => [];
}

class MonthCloseChecklistLoading extends MonthCloseChecklistState {
  const MonthCloseChecklistLoading();
  @override
  List<Object?> get props => [];
}

/// No previous month is open — nothing to show.
class MonthCloseChecklistNone extends MonthCloseChecklistState {
  const MonthCloseChecklistNone();
  @override
  List<Object?> get props => [];
}

/// A previous month needs closing. [expenses] may be empty (all resolved,
/// ready to close) or non-empty (blockers remain).
class MonthCloseChecklistPending extends MonthCloseChecklistState {
  const MonthCloseChecklistPending({
    required this.month,
    required this.year,
    required this.monthName,
    required this.expenses,
    this.actioningExpenseId,
  });

  final int month;
  final int year;
  final String monthName;
  final List<ExpenseEntity> expenses;

  /// Non-null while a specific expense is being approved/rejected.
  final String? actioningExpenseId;

  bool get hasBlockers => expenses.isNotEmpty;
  bool get canClose => expenses.isEmpty;

  MonthCloseChecklistPending copyWith({
    List<ExpenseEntity>? expenses,
    String? actioningExpenseId,
    bool clearActioning = false,
  }) =>
      MonthCloseChecklistPending(
        month: month,
        year: year,
        monthName: monthName,
        expenses: expenses ?? this.expenses,
        actioningExpenseId:
            clearActioning ? null : (actioningExpenseId ?? this.actioningExpenseId),
      );

  @override
  List<Object?> get props =>
      [month, year, monthName, expenses, actioningExpenseId];
}

/// The month is in the process of being closed.
class MonthCloseChecklistClosing extends MonthCloseChecklistState {
  const MonthCloseChecklistClosing({
    required this.month,
    required this.year,
    required this.monthName,
  });
  final int month;
  final int year;
  final String monthName;
  @override
  List<Object?> get props => [month, year];
}

/// Month closed successfully.
class MonthCloseChecklistClosed extends MonthCloseChecklistState {
  const MonthCloseChecklistClosed({
    required this.month,
    required this.year,
    required this.monthName,
  });
  final int month;
  final int year;
  final String monthName;
  @override
  List<Object?> get props => [month, year];
}

/// An error occurred. [previous] holds the last known good state so the UI
/// can keep showing the checklist while the error is surfaced.
class MonthCloseChecklistError extends MonthCloseChecklistState {
  const MonthCloseChecklistError(this.message, {this.previous});
  final String message;
  final MonthCloseChecklistState? previous;
  @override
  List<Object?> get props => [message, previous];
}
