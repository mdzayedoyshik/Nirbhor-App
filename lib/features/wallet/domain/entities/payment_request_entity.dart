import 'package:equatable/equatable.dart';

class PaymentRequestEntity extends Equatable {
  const PaymentRequestEntity({
    required this.id,
    this.requestedByName,
    this.requestedToName,
    required this.requestedTo,
    required this.amount,
    required this.status,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String? requestedByName;
  final String? requestedToName;
  final String requestedTo;
  final double amount;
  final String status; // 'pending' | 'paid' | 'cancelled'
  final String? note;
  final String createdAt;

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isCancelled => status == 'cancelled';

  @override
  List<Object?> get props => [
        id,
        requestedByName,
        requestedToName,
        requestedTo,
        amount,
        status,
        note,
        createdAt,
      ];
}
