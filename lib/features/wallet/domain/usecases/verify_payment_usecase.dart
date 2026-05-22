import '../entities/verify_payment_result_entity.dart';
import '../repositories/wallet_repository.dart';

class VerifyPaymentUseCase {
  VerifyPaymentUseCase(this._repository);
  final WalletRepository _repository;

  Future<VerifyPaymentResultEntity> call(String flatId, String paymentId) =>
      _repository.verifyPayment(flatId, paymentId);
}
