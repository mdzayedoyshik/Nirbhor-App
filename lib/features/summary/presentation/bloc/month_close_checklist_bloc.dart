import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../expense/domain/usecases/approve_expense_usecase.dart';
import '../../../expense/domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/close_month_usecase.dart';
import '../../domain/usecases/get_month_close_status_usecase.dart';

part 'month_close_checklist_event.dart';
part 'month_close_checklist_state.dart';

class MonthCloseChecklistBloc
    extends Bloc<MonthCloseChecklistEvent, MonthCloseChecklistState> {
  MonthCloseChecklistBloc({
    required GetMonthCloseStatusUseCase getStatus,
    required ApproveExpenseUseCase approveExpense,
    required DeleteExpenseUseCase deleteExpense,
    required CloseMonthUseCase closeMonth,
  })  : _getStatus = getStatus,
        _approveExpense = approveExpense,
        _deleteExpense = deleteExpense,
        _closeMonth = closeMonth,
        super(const MonthCloseChecklistInitial()) {
    on<MonthCloseChecklistStatusRequested>(_onStatus);
    on<MonthCloseChecklistExpenseApproved>(_onApprove);
    on<MonthCloseChecklistExpenseRejected>(_onReject);
    on<MonthCloseChecklistCloseRequested>(_onClose);
  }

  final GetMonthCloseStatusUseCase _getStatus;
  final ApproveExpenseUseCase _approveExpense;
  final DeleteExpenseUseCase _deleteExpense;
  final CloseMonthUseCase _closeMonth;

  // ── Status fetch ─────────────────────────────────────────────────────────────

  Future<void> _onStatus(
    MonthCloseChecklistStatusRequested event,
    Emitter<MonthCloseChecklistState> emit,
  ) async {
    emit(const MonthCloseChecklistLoading());
    try {
      final status = await _getStatus(event.flatId);
      if (status.isNone) {
        emit(const MonthCloseChecklistNone());
      } else {
        emit(MonthCloseChecklistPending(
          month: status.month!,
          year: status.year!,
          monthName: status.monthName ?? '',
          expenses: status.unapprovedExpenses,
        ));
      }
    } catch (e) {
      emit(MonthCloseChecklistError(_msg(e)));
    }
  }

  // ── Inline approve ───────────────────────────────────────────────────────────

  Future<void> _onApprove(
    MonthCloseChecklistExpenseApproved event,
    Emitter<MonthCloseChecklistState> emit,
  ) async {
    final current = state;
    if (current is! MonthCloseChecklistPending) return;
    // Optimistically mark the expense as being actioned
    emit(current.copyWith(actioningExpenseId: event.expenseId));
    try {
      await _approveExpense(event.flatId, event.expenseId);
      // Re-fetch to get the updated list from the server
      final status = await _getStatus(event.flatId);
      if (status.isNone) {
        emit(const MonthCloseChecklistNone());
      } else {
        emit(MonthCloseChecklistPending(
          month: status.month!,
          year: status.year!,
          monthName: status.monthName ?? current.monthName,
          expenses: status.unapprovedExpenses,
        ));
      }
    } catch (e) {
      emit(MonthCloseChecklistError(_msg(e), previous: current));
    }
  }

  // ── Inline reject (delete) ───────────────────────────────────────────────────

  Future<void> _onReject(
    MonthCloseChecklistExpenseRejected event,
    Emitter<MonthCloseChecklistState> emit,
  ) async {
    final current = state;
    if (current is! MonthCloseChecklistPending) return;
    emit(current.copyWith(actioningExpenseId: event.expenseId));
    try {
      await _deleteExpense(event.flatId, event.expenseId);
      // Re-fetch to get the updated list from the server
      final status = await _getStatus(event.flatId);
      if (status.isNone) {
        emit(const MonthCloseChecklistNone());
      } else {
        emit(MonthCloseChecklistPending(
          month: status.month!,
          year: status.year!,
          monthName: status.monthName ?? current.monthName,
          expenses: status.unapprovedExpenses,
        ));
      }
    } catch (e) {
      emit(MonthCloseChecklistError(_msg(e), previous: current));
    }
  }

  // ── Manual close ─────────────────────────────────────────────────────────────

  Future<void> _onClose(
    MonthCloseChecklistCloseRequested event,
    Emitter<MonthCloseChecklistState> emit,
  ) async {
    final current = state;
    if (current is! MonthCloseChecklistPending) return;
    emit(MonthCloseChecklistClosing(
      month: event.month,
      year: event.year,
      monthName: current.monthName,
    ));
    try {
      await _closeMonth(event.flatId, event.month, event.year);
      emit(MonthCloseChecklistClosed(
        month: event.month,
        year: event.year,
        monthName: current.monthName,
      ));
    } catch (e) {
      // On failure, re-fetch the real state so the checklist stays accurate.
      emit(MonthCloseChecklistError(_msg(e), previous: current));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
