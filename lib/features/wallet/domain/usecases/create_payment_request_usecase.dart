import '../entities/payment_request_entity.dart';
import '../repositories/wallet_repository.dart';

class CreatePaymentRequestUseCase {
  CreatePaymentRequestUseCase(this._repository);
  final WalletRepository _repository;

  Future<PaymentRequestEntity> call({
    required String flatId,
    required String requestedTo,
    required double amount,
    String? note,
  }) =>
      _repository.createPaymentRequest(
        flatId: flatId,
        requestedTo: requestedTo,
        amount: amount,
        note: note,
      );
}
