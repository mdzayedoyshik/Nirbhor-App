import 'package:equatable/equatable.dart';

abstract class PaymentsEvent extends Equatable {
  const PaymentsEvent();
}

class PaymentsLoadRequested extends PaymentsEvent {
  const PaymentsLoadRequested(this.flatId, {this.status});
  final String flatId;
  final String? status;
  @override
  List<Object?> get props => [flatId, status];
}

class PaymentVerifyRequested extends PaymentsEvent {
  const PaymentVerifyRequested({
    required this.flatId,
    required this.paymentId,
  });
  final String flatId;
  final String paymentId;
  @override
  List<Object?> get props => [flatId, paymentId];
}

class PaymentRejectRequested extends PaymentsEvent {
  const PaymentRejectRequested({
    required this.flatId,
    required this.paymentId,
    this.reason,
  });
  final String flatId;
  final String paymentId;
  final String? reason;
  @override
  List<Object?> get props => [flatId, paymentId, reason];
}

class PaymentVerifyResultAcknowledged extends PaymentsEvent {
  const PaymentVerifyResultAcknowledged();
  @override
  List<Object?> get props => [];
}
