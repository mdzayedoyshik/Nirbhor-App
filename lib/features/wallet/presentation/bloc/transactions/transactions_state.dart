import 'package:equatable/equatable.dart';

import '../../../domain/entities/transaction_entity.dart';

abstract class TransactionsState extends Equatable {
  const TransactionsState();
}

class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
  @override
  List<Object?> get props => [];
}

class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();
  @override
  List<Object?> get props => [];
}

class TransactionsLoaded extends TransactionsState {
  const TransactionsLoaded({
    required this.transactions,
    required this.page,
    required this.total,
    this.isLoadingMore = false,
    this.typeFilter,
  });
  final List<TransactionEntity> transactions;
  final int page;
  final int total;
  final bool isLoadingMore;
  final String? typeFilter;

  bool get hasMore => transactions.length < total;

  @override
  List<Object?> get props =>
      [transactions, page, total, isLoadingMore, typeFilter];
}

class TransactionsError extends TransactionsState {
  const TransactionsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
