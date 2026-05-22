import 'package:equatable/equatable.dart';

abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();
}

class TransactionsLoadRequested extends TransactionsEvent {
  const TransactionsLoadRequested(
    this.flatId, {
    this.type,
    this.category,
    this.from,
    this.to,
    this.memberId,
  });
  final String flatId;
  final String? type;
  final String? category;
  final String? from;
  final String? to;
  final String? memberId;
  @override
  List<Object?> get props => [flatId, type, category, from, to, memberId];
}

class TransactionsLoadMoreRequested extends TransactionsEvent {
  const TransactionsLoadMoreRequested(this.flatId);
  final String flatId;
  @override
  List<Object?> get props => [flatId];
}
