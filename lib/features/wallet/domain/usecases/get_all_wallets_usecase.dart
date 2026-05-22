import '../entities/wallet_member_summary_entity.dart';
import '../repositories/wallet_repository.dart';

class GetAllWalletsUseCase {
  GetAllWalletsUseCase(this._repository);
  final WalletRepository _repository;

  Future<List<WalletMemberSummaryEntity>> call(String flatId) =>
      _repository.getAllWallets(flatId);
}
