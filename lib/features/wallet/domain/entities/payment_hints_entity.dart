import 'package:equatable/equatable.dart';

class PaymentHintsEntity extends Equatable {
  const PaymentHintsEntity({
    required this.flatId,
    required this.suggestedMealAmount,
    required this.suggestedHouseholdAmount,
    required this.updatedAt,
  });

  final String flatId;
  final double suggestedMealAmount;
  final double suggestedHouseholdAmount;
  final String updatedAt;

  @override
  List<Object?> get props => [
        flatId,
        suggestedMealAmount,
        suggestedHouseholdAmount,
        updatedAt,
      ];
}
