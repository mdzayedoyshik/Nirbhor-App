import '../entities/finalize_exit_entity.dart';
import '../repositories/member_repository.dart';

class FinalizeExitUseCase {
  final MemberRepository _repository;
  FinalizeExitUseCase(this._repository);

  Future<FinalizeExitEntity> call({
    required String flatId,
    required String memberId,
  }) => _repository.finalizeExit(flatId: flatId, memberId: memberId);
}
