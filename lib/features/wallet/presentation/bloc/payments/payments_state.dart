import 'package:equatable/equatable.dart';

import '../../../domain/entities/payment_entity.dart';
import '../../../domain/entities/verify_payment_result_entity.dart';

abstract class PaymentsState extends Equatable {
  const PaymentsState();
}

class PaymentsInitial extends PaymentsState {
  const PaymentsInitial();
  @override
  List<Object?> get props => [];
}

class PaymentsLoading extends PaymentsState {
  const PaymentsLoading();
  @override
  List<Object?> get props => [];
}

class PaymentsLoaded extends PaymentsState {
  const PaymentsLoaded(this.payments, {this.statusFilter});
  final List<PaymentEntity> payments;
  final String? statusFilter;
  @override
  List<Object?> get props => [payments, statusFilter];
}

class PaymentsActionLoading extends PaymentsState {
  const PaymentsActionLoading(this.payments);
  final List<PaymentEntity> payments;
  @override
  List<Object?> get props => [payments];
}

class PaymentVerifySuccess extends PaymentsState {
  const PaymentVerifySuccess({
    required this.result,
    required this.payments,
  });
  final VerifyPaymentResultEntity result;
  final List<PaymentEntity> payments;
  @override
  List<Object?> get props => [result, payments];
}

class PaymentRejectSuccess extends PaymentsState {
  const PaymentRejectSuccess(this.payments);
  final List<PaymentEntity> payments;
  @override
  List<Object?> get props => [payments];
}

class PaymentsActionError extends PaymentsState {
  const PaymentsActionError({
    required this.message,
    required this.payments,
  });
  final String message;
  final List<PaymentEntity> payments;
  @override
  List<Object?> get props => [message, payments];
}

class PaymentsError extends PaymentsState {
  const PaymentsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
