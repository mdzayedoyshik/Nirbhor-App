import 'package:equatable/equatable.dart';

abstract class PaymentRequestsEvent extends Equatable {
  const PaymentRequestsEvent();
}

class PaymentRequestsLoadRequested extends PaymentRequestsEvent {
  const PaymentRequestsLoadRequested(this.flatId, {this.status});
  final String flatId;
  final String? status;
  @override
  List<Object?> get props => [flatId, status];
}

class PaymentRequestCreateRequested extends PaymentRequestsEvent {
  const PaymentRequestCreateRequested({
    required this.flatId,
    required this.requestedTo,
    required this.amount,
    this.note,
  });
  final String flatId;
  final String requestedTo;
  final double amount;
  final String? note;
  @override
  List<Object?> get props => [flatId, requestedTo, amount, note];
}

class PaymentRequestBulkCreateRequested extends PaymentRequestsEvent {
  const PaymentRequestBulkCreateRequested({
    required this.flatId,
    required this.memberIds,
    required this.amount,
    this.note,
  });
  final String flatId;
  final List<String> memberIds;
  final double amount;
  final String? note;
  @override
  List<Object?> get props => [flatId, memberIds, amount, note];
}

class PaymentRequestCancelRequested extends PaymentRequestsEvent {
  const PaymentRequestCancelRequested({
    required this.flatId,
    required this.requestId,
  });
  final String flatId;
  final String requestId;
  @override
  List<Object?> get props => [flatId, requestId];
}
