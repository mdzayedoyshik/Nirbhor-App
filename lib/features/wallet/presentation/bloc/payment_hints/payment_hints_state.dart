import 'package:equatable/equatable.dart';

import '../../../domain/entities/payment_hints_entity.dart';

abstract class PaymentHintsState extends Equatable {
  const PaymentHintsState();
}

class PaymentHintsInitial extends PaymentHintsState {
  const PaymentHintsInitial();
  @override
  List<Object?> get props => [];
}

class PaymentHintsLoading extends PaymentHintsState {
  const PaymentHintsLoading();
  @override
  List<Object?> get props => [];
}

class PaymentHintsLoaded extends PaymentHintsState {
  const PaymentHintsLoaded(this.hints);
  final PaymentHintsEntity hints;
  @override
  List<Object?> get props => [hints];
}

class PaymentHintsActionLoading extends PaymentHintsState {
  const PaymentHintsActionLoading(this.hints);
  final PaymentHintsEntity hints;
  @override
  List<Object?> get props => [hints];
}

class PaymentHintsUpdateSuccess extends PaymentHintsState {
  const PaymentHintsUpdateSuccess(this.hints);
  final PaymentHintsEntity hints;
  @override
  List<Object?> get props => [hints];
}

class PaymentHintsError extends PaymentHintsState {
  const PaymentHintsError(this.message, {this.hints});
  final String message;
  final PaymentHintsEntity? hints;
  @override
  List<Object?> get props => [message, hints];
}
