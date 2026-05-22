import '../../domain/entities/expense_entity.dart';

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.flatId,
    required super.paidBy,
    required super.paidByName,
    required super.amount,
    required super.expenseCategory,
    super.description,
    required super.date,
    required super.isApproved,
    super.approvedBy,
    super.approvedByName,
    super.approvedAt,
    required super.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
        id: json['id'] as String,
        flatId: json['flat_id'] as String,
        paidBy: json['paid_by'] as String,
        paidByName: json['paid_by_name'] as String,
        amount: (json['amount'] as num).toDouble(),
        expenseCategory: json['expense_category'] as String,
        description: json['description'] as String?,
        date: json['date'] as String,
        isApproved: json['is_approved'] as bool,
        approvedBy: json['approved_by'] as String?,
        approvedByName: json['approved_by_name'] as String?,
        approvedAt: json['approved_at'] as String?,
        createdAt: json['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'flat_id': flatId,
        'paid_by': paidBy,
        'paid_by_name': paidByName,
        'amount': amount,
        'expense_category': expenseCategory,
        'description': description,
        'date': date,
        'is_approved': isApproved,
        'approved_by': approvedBy,
        'approved_by_name': approvedByName,
        'approved_at': approvedAt,
        'created_at': createdAt,
      };
}
