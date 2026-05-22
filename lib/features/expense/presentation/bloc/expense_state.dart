import 'package:equatable/equatable.dart';

import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_summary_entity.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();
}

class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
  @override
  List<Object?> get props => [];
}

class ExpenseListLoading extends ExpenseState {
  const ExpenseListLoading();
  @override
  List<Object?> get props => [];
}

class ExpenseListLoaded extends ExpenseState {
  const ExpenseListLoaded({
    required this.expenses,
    required this.pagination,
    required this.month,
    required this.year,
    this.summary,
    this.isLoadingMore = false,
  });

  final List<ExpenseEntity> expenses;
  final Map<String, dynamic> pagination;
  final int month;
  final int year;
  final ExpenseSummaryEntity? summary;
  final bool isLoadingMore;

  bool get hasMore {
    final page = pagination['page'] as int? ?? 1;
    final totalPages = pagination['total_pages'] as int? ?? 1;
    return page < totalPages;
  }

  ExpenseListLoaded copyWith({
    List<ExpenseEntity>? expenses,
    Map<String, dynamic>? pagination,
    int? month,
    int? year,
    ExpenseSummaryEntity? summary,
    bool? isLoadingMore,
  }) =>
      ExpenseListLoaded(
        expenses: expenses ?? this.expenses,
        pagination: pagination ?? this.pagination,
        month: month ?? this.month,
        year: year ?? this.year,
        summary: summary ?? this.summary,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props =>
      [expenses, pagination, month, year, summary, isLoadingMore];
}

class ExpenseDetailLoading extends ExpenseState {
  const ExpenseDetailLoading();
  @override
  List<Object?> get props => [];
}

class ExpenseDetailLoaded extends ExpenseState {
  const ExpenseDetailLoaded(this.expense);
  final ExpenseEntity expense;
  @override
  List<Object?> get props => [expense];
}

class ExpenseActionLoading extends ExpenseState {
  const ExpenseActionLoading();
  @override
  List<Object?> get props => [];
}

class ExpenseActionSuccess extends ExpenseState {
  const ExpenseActionSuccess({
    required this.message,
    this.updatedExpense,
    this.approveResult,
  });
  final String message;
  final ExpenseEntity? updatedExpense;
  final Map<String, dynamic>? approveResult;
  @override
  List<Object?> get props => [message, updatedExpense, approveResult];
}

class ExpenseError extends ExpenseState {
  const ExpenseError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
