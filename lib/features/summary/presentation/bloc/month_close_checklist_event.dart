part of 'month_close_checklist_bloc.dart';

abstract class MonthCloseChecklistEvent extends Equatable {
  const MonthCloseChecklistEvent();
}

/// Fetch the close status for the oldest unclosed previous month.
class MonthCloseChecklistStatusRequested extends MonthCloseChecklistEvent {
  const MonthCloseChecklistStatusRequested(this.flatId);
  final String flatId;
  @override
  List<Object?> get props => [flatId];
}

/// Approve a single expense inline from the checklist.
class MonthCloseChecklistExpenseApproved extends MonthCloseChecklistEvent {
  const MonthCloseChecklistExpenseApproved({
    required this.flatId,
    required this.expenseId,
  });
  final String flatId;
  final String expenseId;
  @override
  List<Object?> get props => [flatId, expenseId];
}

/// Reject (delete) a single expense inline from the checklist.
class MonthCloseChecklistExpenseRejected extends MonthCloseChecklistEvent {
  const MonthCloseChecklistExpenseRejected({
    required this.flatId,
    required this.expenseId,
  });
  final String flatId;
  final String expenseId;
  @override
  List<Object?> get props => [flatId, expenseId];
}

/// Close the month after all blockers are resolved.
class MonthCloseChecklistCloseRequested extends MonthCloseChecklistEvent {
  const MonthCloseChecklistCloseRequested({
    required this.flatId,
    required this.month,
    required this.year,
  });
  final String flatId;
  final int month;
  final int year;
  @override
  List<Object?> get props => [flatId, month, year];
}
