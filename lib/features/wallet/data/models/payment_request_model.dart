import '../../domain/entities/payment_request_entity.dart';

class PaymentRequestModel extends PaymentRequestEntity {
  const PaymentRequestModel({
    required super.id,
    super.requestedByName,
    super.requestedToName,
    required super.requestedTo,
    required super.amount,
    required super.status,
    super.note,
    required super.createdAt,
  });

  factory PaymentRequestModel.fromJson(Map<String, dynamic> json) =>
      PaymentRequestModel(
        id: json['id'] as String,
        requestedByName: json['requested_by_name'] as String?,
        requestedToName: json['requested_to_name'] as String?,
        requestedTo: json['requested_to'] as String,
        amount: (json['amount'] as num).toDouble(),
        status: json['status'] as String,
        note: json['note'] as String?,
        createdAt: json['created_at'] as String,
      );
}
