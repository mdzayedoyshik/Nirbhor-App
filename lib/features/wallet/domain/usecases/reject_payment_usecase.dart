import '../repositories/wallet_repository.dart';

class RejectPaymentUseCase {
  RejectPaymentUseCase(this._repository);
  final WalletRepository _repository;

  Future<void> call(String flatId, String paymentId, {String? reason}) =>
      _repository.rejectPayment(flatId, paymentId, reason: reason);
}
