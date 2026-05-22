import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    super.flatMemberId,
    super.memberName,
    required super.amount,
    required super.transactionType,
    super.category,
    required super.description,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        flatMemberId: json['flat_member_id'] as String?,
        memberName: json['member_name'] as String?,
        amount: (json['amount'] as num).toDouble(),
        transactionType: json['transaction_type'] as String,
        category: json['category'] as String?,
        description: json['description'] as String,
        createdAt: json['created_at'] as String,
      );
}
