import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  const TransactionEntity({
    required this.id,
    this.flatMemberId,
    this.memberName,
    required this.amount,
    required this.transactionType,
    this.category,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String? flatMemberId;
  final String? memberName;
  final double amount;
  final String transactionType; // 'deposit' | 'deduction' | 'refund'
  final String? category; // 'fixed' | 'meal' | 'household' | null
  final String description;
  final String createdAt;

  bool get isDeposit => transactionType == 'deposit';
  bool get isDeduction => transactionType == 'deduction';
  bool get isRefund => transactionType == 'refund';

  bool get isFlatLevel => flatMemberId == null;

  @override
  List<Object?> get props => [
        id,
        flatMemberId,
        memberName,
        amount,
        transactionType,
        category,
        description,
        createdAt,
      ];
}
