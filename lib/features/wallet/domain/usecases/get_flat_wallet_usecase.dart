import '../entities/flat_wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class GetFlatWalletUseCase {
  GetFlatWalletUseCase(this._repository);
  final WalletRepository _repository;

  Future<FlatWalletEntity> call(String flatId) =>
      _repository.getFlatWallet(flatId);
}
