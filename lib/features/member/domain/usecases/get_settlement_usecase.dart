import '../entities/settlement_entity.dart';
import '../repositories/member_repository.dart';

class GetSettlementUseCase {
  final MemberRepository _repository;
  GetSettlementUseCase(this._repository);

  Future<SettlementEntity> call({
    required String flatId,
    required String memberId,
  }) => _repository.getSettlement(flatId: flatId, memberId: memberId);
}
