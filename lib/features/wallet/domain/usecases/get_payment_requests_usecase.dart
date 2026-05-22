import '../entities/payment_request_entity.dart';
import '../repositories/wallet_repository.dart';

class GetPaymentRequestsUseCase {
  GetPaymentRequestsUseCase(this._repository);
  final WalletRepository _repository;

  Future<List<PaymentRequestEntity>> call(
    String flatId, {
    String? status,
    String? memberId,
  }) =>
      _repository.getPaymentRequests(flatId, status: status, memberId: memberId);
}
