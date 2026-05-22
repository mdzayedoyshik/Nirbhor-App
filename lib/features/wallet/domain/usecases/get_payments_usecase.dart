import '../entities/payment_entity.dart';
import '../repositories/wallet_repository.dart';

class GetPaymentsUseCase {
  GetPaymentsUseCase(this._repository);
  final WalletRepository _repository;

  Future<List<PaymentEntity>> call(
    String flatId, {
    String? status,
    String? memberId,
  }) =>
      _repository.getPayments(flatId, status: status, memberId: memberId);
}
