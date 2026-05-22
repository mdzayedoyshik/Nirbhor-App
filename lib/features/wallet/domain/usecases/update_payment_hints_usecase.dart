import '../entities/payment_hints_entity.dart';
import '../repositories/wallet_repository.dart';

class UpdatePaymentHintsUseCase {
  UpdatePaymentHintsUseCase(this._repository);
  final WalletRepository _repository;

  Future<PaymentHintsEntity> call(
    String flatId, {
    double? suggestedMealAmount,
    double? suggestedHouseholdAmount,
  }) =>
      _repository.updatePaymentHints(
        flatId,
        suggestedMealAmount: suggestedMealAmount,
        suggestedHouseholdAmount: suggestedHouseholdAmount,
      );
}
