import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();
}

class WalletSummaryRequested extends WalletEvent {
  const WalletSummaryRequested(this.flatId);
  final String flatId;
  @override
  List<Object?> get props => [flatId];
}

class WalletPaymentSubmitRequested extends WalletEvent {
  const WalletPaymentSubmitRequested({
    required this.flatId,
    required this.amount,
    required this.paymentMethod,
    this.paymentRequestId,
    this.note,
  });
  final String flatId;
  final double amount;
  final String paymentMethod;
  final String? paymentRequestId;
  final String? note;
  @override
  List<Object?> get props =>
      [flatId, amount, paymentMethod, paymentRequestId, note];
}
