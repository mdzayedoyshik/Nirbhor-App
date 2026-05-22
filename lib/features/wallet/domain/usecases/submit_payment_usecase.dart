import '../entities/payment_entity.dart';
import '../repositories/wallet_repository.dart';

class SubmitPaymentUseCase {
  SubmitPaymentUseCase(this._repository);
  final WalletRepository _repository;

  Future<PaymentEntity> call({
    required String flatId,
    required double amount,
    required String paymentMethod,
    String? paymentRequestId,
    String? note,
  }) =>
      _repository.submitPayment(
        flatId: flatId,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentRequestId: paymentRequestId,
        note: note,
      );
}
