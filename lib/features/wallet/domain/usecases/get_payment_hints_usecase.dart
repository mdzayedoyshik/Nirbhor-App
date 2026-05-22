import '../entities/payment_hints_entity.dart';
import '../repositories/wallet_repository.dart';

class GetPaymentHintsUseCase {
  GetPaymentHintsUseCase(this._repository);
  final WalletRepository _repository;

  Future<PaymentHintsEntity> call(String flatId) =>
      _repository.getPaymentHints(flatId);
}
