import '../entities/transaction_entity.dart';
import '../repositories/wallet_repository.dart';

class GetTransactionsUseCase {
  GetTransactionsUseCase(this._repository);
  final WalletRepository _repository;

  Future<List<TransactionEntity>> call(
    String flatId, {
    String? memberId,
    String? type,
    String? category,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) =>
      _repository.getTransactions(
        flatId,
        memberId: memberId,
        type: type,
        category: category,
        from: from,
        to: to,
        page: page,
        limit: limit,
      );
}
