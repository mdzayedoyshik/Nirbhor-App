import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  const PaymentEntity({
    required this.id,
    this.fromMemberName,
    required this.fromMember,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.paymentRequestId,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String? fromMemberName;
  final String fromMember;
  final double amount;
  final String paymentMethod;
  final String status; // 'pending' | 'verified' | 'rejected' | 'cancelled'
  final String? paymentRequestId;
  final String? note;
  final String createdAt;

  bool get isPending => status == 'pending';
  bool get isVerified => status == 'verified';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  @override
  List<Object?> get props => [
        id,
        fromMemberName,
        fromMember,
        amount,
        paymentMethod,
        status,
        paymentRequestId,
        note,
        createdAt,
      ];
}
