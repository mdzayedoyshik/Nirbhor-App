import 'package:equatable/equatable.dart';

import '../../../domain/entities/payment_request_entity.dart';

abstract class PaymentRequestsState extends Equatable {
  const PaymentRequestsState();
}

class PaymentRequestsInitial extends PaymentRequestsState {
  const PaymentRequestsInitial();
  @override
  List<Object?> get props => [];
}

class PaymentRequestsLoading extends PaymentRequestsState {
  const PaymentRequestsLoading();
  @override
  List<Object?> get props => [];
}

class PaymentRequestsLoaded extends PaymentRequestsState {
  const PaymentRequestsLoaded(this.requests, {this.statusFilter});
  final List<PaymentRequestEntity> requests;
  final String? statusFilter;
  @override
  List<Object?> get props => [requests, statusFilter];
}

class PaymentRequestsActionLoading extends PaymentRequestsState {
  const PaymentRequestsActionLoading(this.requests);
  final List<PaymentRequestEntity> requests;
  @override
  List<Object?> get props => [requests];
}

class PaymentRequestCreateSuccess extends PaymentRequestsState {
  const PaymentRequestCreateSuccess(this.requests);
  final List<PaymentRequestEntity> requests;
  @override
  List<Object?> get props => [requests];
}

class PaymentRequestBulkCreateSuccess extends PaymentRequestsState {
  const PaymentRequestBulkCreateSuccess(this.requests,
      {required this.sentCount, required this.skippedCount});
  final List<PaymentRequestEntity> requests;
  final int sentCount;
  final int skippedCount;
  @override
  List<Object?> get props => [requests, sentCount, skippedCount];
}

class PaymentRequestCancelSuccess extends PaymentRequestsState {
  const PaymentRequestCancelSuccess(this.requests);
  final List<PaymentRequestEntity> requests;
  @override
  List<Object?> get props => [requests];
}

class PaymentRequestsActionError extends PaymentRequestsState {
  const PaymentRequestsActionError({
    required this.message,
    required this.requests,
  });
  final String message;
  final List<PaymentRequestEntity> requests;
  @override
  List<Object?> get props => [message, requests];
}

class PaymentRequestsError extends PaymentRequestsState {
  const PaymentRequestsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
