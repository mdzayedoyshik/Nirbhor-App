import 'package:equatable/equatable.dart';

import '../../../expense/domain/entities/expense_entity.dart';

/// Returned by the `GET /flats/:id/monthly-summary/close-status` endpoint.
///
/// [status]:
///   - `'none'`        — no previous month is open; nothing to do.
///   - `'blocked'`     — previous month is open AND has unapproved expenses.
///   - `'needs_close'` — previous month is open but all expenses are approved;
///                       ready to close (auto-close may not have fired yet).
class MonthCloseStatusEntity extends Equatable {
  const MonthCloseStatusEntity({
    required this.status,
    this.month,
    this.year,
    this.monthName,
    this.unapprovedExpenses = const [],
  });

  final String status;
  final int? month;
  final int? year;
  final String? monthName;
  final List<ExpenseEntity> unapprovedExpenses;

  bool get isNone => status == 'none';
  bool get isBlocked => status == 'blocked';
  bool get needsClose => status == 'needs_close';
  bool get requiresAttention => isBlocked || needsClose;

  @override
  List<Object?> get props => [status, month, year, unapprovedExpenses];
}
