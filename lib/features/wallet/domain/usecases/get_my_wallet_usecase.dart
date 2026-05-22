import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class GetMyWalletUseCase {
  GetMyWalletUseCase(this._repository);
  final WalletRepository _repository;

  Future<WalletEntity> call(String flatId) => _repository.getMyWallet(flatId);
}
