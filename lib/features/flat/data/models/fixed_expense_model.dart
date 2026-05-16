import '../../domain/entities/fixed_expense_entity.dart';

class FixedExpenseModel extends FixedExpenseEntity {
  const FixedExpenseModel({
    required super.id,
    required super.expenseType,
    required super.amount,
  });

  factory FixedExpenseModel.fromJson(Map<String, dynamic> json) =>
      FixedExpenseModel(
        id: json['id'] as String,
        expenseType: json['expense_type'] as String,
        amount: (json['amount'] as num).toDouble(),
      );
}
