import 'package:equatable/equatable.dart';

class ExpenseEntity extends Equatable {
  const ExpenseEntity({
    required this.id,
    required this.flatId,
    required this.paidBy,
    required this.paidByName,
    required this.amount,
    required this.expenseCategory,
    this.description,
    required this.date,
    required this.isApproved,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    required this.createdAt,
  });

  final String id;
  final String flatId;
  final String paidBy;
  final String paidByName;
  final double amount;
  final String expenseCategory; // 'meal' | 'household' | 'fixed'
  final String? description;
  final String date;
  final bool isApproved;
  final String? approvedBy;
  final String? approvedByName;
  final String? approvedAt;
  final String createdAt;

  bool get isMeal => expenseCategory == 'meal';
  bool get isHousehold => expenseCategory == 'household';
  bool get isFixed => expenseCategory == 'fixed';

  @override
  List<Object?> get props => [
        id,
        flatId,
        paidBy,
        paidByName,
        amount,
        expenseCategory,
        description,
        date,
        isApproved,
        approvedBy,
        approvedByName,
        approvedAt,
        createdAt,
      ];
}
