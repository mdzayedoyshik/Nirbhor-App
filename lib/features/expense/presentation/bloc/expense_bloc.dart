import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_summary_entity.dart';
import '../../domain/usecases/approve_expense_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/get_expense_detail_usecase.dart';
import '../../domain/usecases/get_expense_summary_usecase.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../../domain/usecases/record_expense_usecase.dart';
import '../../domain/usecases/update_expense_usecase.dart';
import 'expense_event.dart';
import 'expense_state.dart';

export 'expense_event.dart';
export 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  ExpenseBloc({
    required GetExpensesUseCase getExpenses,
    required GetExpenseSummaryUseCase getExpenseSummary,
    required GetExpenseDetailUseCase getExpenseDetail,
    required RecordExpenseUseCase recordExpense,
    required ApproveExpenseUseCase approveExpense,
    required UpdateExpenseUseCase updateExpense,
    required DeleteExpenseUseCase deleteExpense,
  })  : _getExpenses = getExpenses,
        _getExpenseSummary = getExpenseSummary,
        _getExpenseDetail = getExpenseDetail,
        _recordExpense = recordExpense,
        _approveExpense = approveExpense,
        _updateExpense = updateExpense,
        _deleteExpense = deleteExpense,
        super(const ExpenseInitial()) {
    on<ExpensesLoadRequested>(_onLoad);
    on<ExpensesLoadMoreRequested>(_onLoadMore);
    on<ExpenseSummaryRequested>(_onSummary);
    on<ExpenseDetailRequested>(_onDetail);
    on<ExpenseRecordRequested>(_onRecord);
    on<ExpenseApproveRequested>(_onApprove);
    on<ExpenseUpdateRequested>(_onUpdate);
    on<ExpenseDeleteRequested>(_onDelete);
  }

  final GetExpensesUseCase _getExpenses;
  final GetExpenseSummaryUseCase _getExpenseSummary;
  final GetExpenseDetailUseCase _getExpenseDetail;
  final RecordExpenseUseCase _recordExpense;
  final ApproveExpenseUseCase _approveExpense;
  final UpdateExpenseUseCase _updateExpense;
  final DeleteExpenseUseCase _deleteExpense;

  // Caches the last fully loaded list state to avoid loading spinner on revisit
  ExpenseListLoaded? _cachedList;
  bool _cacheInvalidated = false;

  void _invalidateCache() {
    _cacheInvalidated = true;
    _cachedList = null;
  }

  Future<void> _onLoad(
    ExpensesLoadRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    final cached = _cachedList;
    // Use cache only when filters match exactly and cache is valid
    final now = DateTime.now();
    final reqMonth = event.month ?? now.month;
    final reqYear = event.year ?? now.year;
    final cacheMatches = cached != null &&
        !_cacheInvalidated &&
        cached.month == reqMonth &&
        cached.year == reqYear;

    if (cacheMatches) {
      emit(cached);
      try {
        final result = await _getExpenses(
          event.flatId,
          category: event.category,
          isApproved: event.isApproved,
          month: event.month,
          year: event.year,
          page: 1,
        );
        ExpenseSummaryEntity? summary;
        try {
          summary = await _getExpenseSummary(event.flatId, reqMonth, reqYear);
        } catch (_) {}
        final fresh = ExpenseListLoaded(
          expenses: result['expenses'] as List<ExpenseEntity>,
          pagination: result['pagination'] as Map<String, dynamic>,
          month: reqMonth,
          year: reqYear,
          summary: summary,
        );
        _cachedList = fresh;
        _cacheInvalidated = false;
        emit(fresh);
      } catch (_) {
        // Keep showing cached data silently
      }
    } else {
      emit(const ExpenseListLoading());
      try {
        final result = await _getExpenses(
          event.flatId,
          category: event.category,
          isApproved: event.isApproved,
          month: event.month,
          year: event.year,
          page: 1,
        );

        ExpenseSummaryEntity? summary;
        try {
          summary = await _getExpenseSummary(event.flatId, reqMonth, reqYear);
        } catch (_) {}

        final loaded = ExpenseListLoaded(
          expenses: result['expenses'] as List<ExpenseEntity>,
          pagination: result['pagination'] as Map<String, dynamic>,
          month: reqMonth,
          year: reqYear,
          summary: summary,
        );
        _cachedList = loaded;
        _cacheInvalidated = false;
        emit(loaded);
      } catch (e) {
        emit(ExpenseError(_msg(e)));
      }
    }
  }

  Future<void> _onLoadMore(
    ExpensesLoadMoreRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    final current = state;
    if (current is! ExpenseListLoaded) return;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final result = await _getExpenses(
        event.flatId,
        category: event.category,
        isApproved: event.isApproved,
        month: event.month,
        year: event.year,
        page: event.nextPage,
      );
      final newExpenses = result['expenses'] as List<ExpenseEntity>;
      emit(current.copyWith(
        expenses: [...current.expenses, ...newExpenses],
        pagination: result['pagination'] as Map<String, dynamic>,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onSummary(
    ExpenseSummaryRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      final summary =
          await _getExpenseSummary(event.flatId, event.month, event.year);
      final current = state;
      if (current is ExpenseListLoaded) {
        emit(current.copyWith(summary: summary));
      }
    } catch (_) {}
  }

  Future<void> _onDetail(
    ExpenseDetailRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseDetailLoading());
    try {
      final expense =
          await _getExpenseDetail(event.flatId, event.expenseId);
      emit(ExpenseDetailLoaded(expense));
    } catch (e) {
      emit(ExpenseError(_msg(e)));
    }
  }

  Future<void> _onRecord(
    ExpenseRecordRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    _invalidateCache();
    emit(const ExpenseActionLoading());
    try {
      final expense = await _recordExpense(
        flatId: event.flatId,
        amount: event.amount,
        category: event.category,
        description: event.description,
        date: event.date,
      );
      emit(ExpenseActionSuccess(
        message: 'Expense recorded successfully.',
        updatedExpense: expense,
      ));
    } catch (e) {
      emit(ExpenseError(_msg(e)));
    }
  }

  Future<void> _onApprove(
    ExpenseApproveRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    _invalidateCache();
    emit(const ExpenseActionLoading());
    try {
      final result = await _approveExpense(event.flatId, event.expenseId);
      emit(ExpenseActionSuccess(
        message: 'Expense approved successfully.',
        updatedExpense: result['expense'] as ExpenseEntity,
        approveResult: result['deduction_result'] as Map<String, dynamic>?,
      ));
    } catch (e) {
      emit(ExpenseError(_msg(e)));
    }
  }

  Future<void> _onUpdate(
    ExpenseUpdateRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    _invalidateCache();
    emit(const ExpenseActionLoading());
    try {
      final expense = await _updateExpense(
        flatId: event.flatId,
        expenseId: event.expenseId,
        amount: event.amount,
        description: event.description,
        date: event.date,
      );
      emit(ExpenseActionSuccess(
        message: 'Expense updated successfully.',
        updatedExpense: expense,
      ));
    } catch (e) {
      emit(ExpenseError(_msg(e)));
    }
  }

  Future<void> _onDelete(
    ExpenseDeleteRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    _invalidateCache();
    emit(const ExpenseActionLoading());
    try {
      await _deleteExpense(event.flatId, event.expenseId);
      emit(const ExpenseActionSuccess(message: 'Expense deleted.'));
    } catch (e) {
      emit(ExpenseError(_msg(e)));
    }
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
