import '../../domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    super.fromMemberName,
    required super.fromMember,
    required super.amount,
    required super.paymentMethod,
    required super.status,
    super.paymentRequestId,
    super.note,
    required super.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'] as String,
        fromMemberName: json['from_member_name'] as String?,
        fromMember: json['from_member'] as String,
        amount: (json['amount'] as num).toDouble(),
        paymentMethod: json['payment_method'] as String,
        status: json['status'] as String,
        paymentRequestId: json['payment_request_id'] as String?,
        note: json['note'] as String?,
        createdAt: json['created_at'] as String,
      );
}
