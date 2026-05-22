import '../../domain/entities/payment_hints_entity.dart';

class PaymentHintsModel extends PaymentHintsEntity {
  const PaymentHintsModel({
    required super.flatId,
    required super.suggestedMealAmount,
    required super.suggestedHouseholdAmount,
    required super.updatedAt,
  });

  factory PaymentHintsModel.fromJson(Map<String, dynamic> json) =>
      PaymentHintsModel(
        flatId: json['flat_id'] as String,
        suggestedMealAmount: (json['suggested_meal_amount'] as num).toDouble(),
        suggestedHouseholdAmount:
            (json['suggested_household_amount'] as num).toDouble(),
        updatedAt: json['updated_at'] as String,
      );
}
