import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/fixed_expense_entity.dart';
import '../../domain/usecases/add_fixed_expense_usecase.dart';
import '../../domain/usecases/delete_fixed_expense_usecase.dart';
import '../../domain/usecases/get_fixed_expenses_usecase.dart';
import '../../domain/usecases/redistribute_usecase.dart';
import '../../domain/usecases/update_fixed_expense_usecase.dart';

part 'fixed_expenses_state.dart';

class FixedExpensesCubit extends Cubit<FixedExpensesState> {
  final GetFixedExpensesUseCase _getExpenses;
  final AddFixedExpenseUseCase _addExpense;
  final UpdateFixedExpenseUseCase _updateExpense;
  final DeleteFixedExpenseUseCase _deleteExpense;
  final RedistributeUseCase _redistribute;

  FixedExpensesCubit({
    required GetFixedExpensesUseCase getExpenses,
    required AddFixedExpenseUseCase addExpense,
    required UpdateFixedExpenseUseCase updateExpense,
    required DeleteFixedExpenseUseCase deleteExpense,
    required RedistributeUseCase redistribute,
  }) : _getExpenses = getExpenses,
       _addExpense = addExpense,
       _updateExpense = updateExpense,
       _deleteExpense = deleteExpense,
       _redistribute = redistribute,
       super(const FixedExpensesInitial());

  Future<void> load(String flatId) async {
    emit(const FixedExpensesLoading());
    try {
      final expenses = await _getExpenses(flatId);
      emit(FixedExpensesLoaded(expenses));
    } catch (e) {
      emit(FixedExpensesError(_message(e)));
    }
  }

  Future<bool> add({
    required String flatId,
    required String expenseType,
    required double amount,
  }) async {
    final current = state;
    emit(const FixedExpensesFormLoading());
    try {
      await _addExpense(
        flatId: flatId,
        expenseType: expenseType,
        amount: amount,
      );
      await load(flatId);
      return true;
    } catch (e) {
      if (current is FixedExpensesLoaded) emit(current);
      emit(FixedExpensesError(_message(e)));
      return false;
    }
  }

  Future<bool> update({
    required String flatId,
    required String expenseId,
    String? expenseType,
    double? amount,
  }) async {
    final current = state;
    emit(const FixedExpensesFormLoading());
    try {
      await _updateExpense(
        flatId: flatId,
        expenseId: expenseId,
        expenseType: expenseType,
        amount: amount,
      );
      await load(flatId);
      return true;
    } catch (e) {
      if (current is FixedExpensesLoaded) emit(current);
      emit(FixedExpensesError(_message(e)));
      return false;
    }
  }

  Future<void> delete({
    required String flatId,
    required String expenseId,
  }) async {
    emit(const FixedExpensesFormLoading());
    try {
      await _deleteExpense(flatId: flatId, expenseId: expenseId);
      await load(flatId);
    } catch (e) {
      emit(FixedExpensesError(_message(e)));
    }
  }

  Future<void> redistribute(String flatId) async {
    emit(const FixedExpensesFormLoading());
    try {
      await _redistribute(flatId);
      await load(flatId);
    } catch (e) {
      emit(FixedExpensesError(_message(e)));
    }
  }

  String _message(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
