import '../repositories/wallet_repository.dart';

class CancelPaymentRequestUseCase {
  CancelPaymentRequestUseCase(this._repository);
  final WalletRepository _repository;

  Future<void> call(String flatId, String requestId) =>
      _repository.cancelPaymentRequest(flatId, requestId);
}
