import 'package:equatable/equatable.dart';

abstract class PaymentHintsEvent extends Equatable {
  const PaymentHintsEvent();
}

class PaymentHintsLoadRequested extends PaymentHintsEvent {
  const PaymentHintsLoadRequested(this.flatId);
  final String flatId;
  @override
  List<Object?> get props => [flatId];
}

class PaymentHintsUpdateRequested extends PaymentHintsEvent {
  const PaymentHintsUpdateRequested({
    required this.flatId,
    this.suggestedMealAmount,
    this.suggestedHouseholdAmount,
  });
  final String flatId;
  final double? suggestedMealAmount;
  final double? suggestedHouseholdAmount;
  @override
  List<Object?> get props =>
      [flatId, suggestedMealAmount, suggestedHouseholdAmount];
}
