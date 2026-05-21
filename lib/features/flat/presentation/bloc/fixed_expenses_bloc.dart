import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/fixed_expense_entity.dart';
import '../../domain/usecases/add_fixed_expense_usecase.dart';
import '../../domain/usecases/delete_fixed_expense_usecase.dart';
import '../../domain/usecases/get_fixed_expenses_usecase.dart';
import '../../domain/usecases/redistribute_usecase.dart';
import '../../domain/usecases/update_fixed_expense_usecase.dart';
import 'fixed_expenses_event.dart';
import 'fixed_expenses_state.dart';

export 'fixed_expenses_event.dart';
export 'fixed_expenses_state.dart';

class FixedExpensesBloc extends Bloc<FixedExpensesEvent, FixedExpensesState> {
  final GetFixedExpensesUseCase _getExpenses;
  final AddFixedExpenseUseCase _addExpense;
  final UpdateFixedExpenseUseCase _updateExpense;
  final DeleteFixedExpenseUseCase _deleteExpense;
  final RedistributeUseCase _redistribute;

  FixedExpensesBloc({
    required GetFixedExpensesUseCase getExpenses,
    required AddFixedExpenseUseCase addExpense,
    required UpdateFixedExpenseUseCase updateExpense,
    required DeleteFixedExpenseUseCase deleteExpense,
    required RedistributeUseCase redistribute,
  })  : _getExpenses = getExpenses,
        _addExpense = addExpense,
        _updateExpense = updateExpense,
        _deleteExpense = deleteExpense,
        _redistribute = redistribute,
        super(const FixedExpensesInitial()) {
    on<FixedExpensesLoadRequested>(_onLoad);
    on<FixedExpenseAddRequested>(_onAdd);
    on<FixedExpenseUpdateRequested>(_onUpdate);
    on<FixedExpenseDeleteRequested>(_onDelete);
    on<FixedExpensesRedistributeRequested>(_onRedistribute);
  }

  Future<void> _onLoad(
    FixedExpensesLoadRequested event,
    Emitter<FixedExpensesState> emit,
  ) async {
    emit(const FixedExpensesLoading());
    try {
      final expenses = await _getExpenses(event.flatId);
      emit(FixedExpensesLoaded(expenses));
    } catch (e) {
      emit(FixedExpensesLoadError(_message(e)));
    }
  }

  Future<void> _onAdd(
    FixedExpenseAddRequested event,
    Emitter<FixedExpensesState> emit,
  ) async {
    final current = _currentExpenses;
    if (current == null) return;
    emit(FixedExpensesActionInProgress(current));
    try {
      await _addExpense(
        flatId: event.flatId,
        expenseType: event.expenseType,
        amount: event.amount,
      );
      final updated = await _getExpenses(event.flatId);
      emit(FixedExpensesActionSuccess(
        expenses: updated,
        message: 'Expense added.',
        action: FixedExpensesAction.add,
      ));
      emit(FixedExpensesLoaded(updated));
    } catch (e) {
      emit(FixedExpensesActionError(expenses: current, message: _message(e)));
      emit(FixedExpensesLoaded(current));
    }
  }

  Future<void> _onUpdate(
    FixedExpenseUpdateRequested event,
    Emitter<FixedExpensesState> emit,
  ) async {
    final current = _currentExpenses;
    if (current == null) return;
    emit(FixedExpensesActionInProgress(current));
    try {
      await _updateExpense(
        flatId: event.flatId,
        expenseId: event.expenseId,
        expenseType: event.expenseType,
        amount: event.amount,
      );
      final updated = await _getExpenses(event.flatId);
      emit(FixedExpensesActionSuccess(
        expenses: updated,
        message: 'Expense updated.',
        action: FixedExpensesAction.update,
      ));
      emit(FixedExpensesLoaded(updated));
    } catch (e) {
      emit(FixedExpensesActionError(expenses: current, message: _message(e)));
      emit(FixedExpensesLoaded(current));
    }
  }

  Future<void> _onDelete(
    FixedExpenseDeleteRequested event,
    Emitter<FixedExpensesState> emit,
  ) async {
    final current = _currentExpenses;
    if (current == null) return;
    emit(FixedExpensesActionInProgress(current));
    try {
      await _deleteExpense(flatId: event.flatId, expenseId: event.expenseId);
      final updated = await _getExpenses(event.flatId);
      emit(FixedExpensesActionSuccess(
        expenses: updated,
        message: 'Expense deleted.',
        action: FixedExpensesAction.delete,
      ));
      emit(FixedExpensesLoaded(updated));
    } catch (e) {
      emit(FixedExpensesActionError(expenses: current, message: _message(e)));
      emit(FixedExpensesLoaded(current));
    }
  }

  Future<void> _onRedistribute(
    FixedExpensesRedistributeRequested event,
    Emitter<FixedExpensesState> emit,
  ) async {
    final current = _currentExpenses;
    if (current == null) return;
    emit(FixedExpensesActionInProgress(current));
    try {
      await _redistribute(event.flatId);
      final updated = await _getExpenses(event.flatId);
      emit(FixedExpensesActionSuccess(
        expenses: updated,
        message: 'Contributions redistributed.',
        action: FixedExpensesAction.redistribute,
      ));
      emit(FixedExpensesLoaded(updated));
    } catch (e) {
      emit(FixedExpensesActionError(expenses: current, message: _message(e)));
      emit(FixedExpensesLoaded(current));
    }
  }

  List<FixedExpenseEntity>? get _currentExpenses {
    final s = state;
    if (s is FixedExpensesLoaded) return s.expenses;
    if (s is FixedExpensesActionInProgress) return s.expenses;
    if (s is FixedExpensesActionError) return s.expenses;
    if (s is FixedExpensesActionSuccess) return s.expenses;
    return null;
  }

  String _message(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
