import '../entities/settlement_entity.dart';
import '../repositories/member_repository.dart';

class InitiateExitUseCase {
  final MemberRepository _repository;
  InitiateExitUseCase(this._repository);

  Future<SettlementEntity> call({
    required String flatId,
    required String memberId,
    double fixedRefund = 0,
  }) => _repository.initiateExit(
    flatId: flatId,
    memberId: memberId,
    fixedRefund: fixedRefund,
  );
}
