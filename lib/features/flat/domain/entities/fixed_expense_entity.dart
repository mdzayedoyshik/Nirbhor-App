import 'package:equatable/equatable.dart';

class FixedExpenseEntity extends Equatable {
  final String id;
  final String expenseType;
  final double amount;

  const FixedExpenseEntity({
    required this.id,
    required this.expenseType,
    required this.amount,
  });

  @override
  List<Object?> get props => [id, expenseType, amount];
}
