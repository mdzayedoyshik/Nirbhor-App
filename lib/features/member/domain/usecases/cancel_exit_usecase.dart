import '../repositories/member_repository.dart';

class CancelExitUseCase {
  final MemberRepository _repository;
  CancelExitUseCase(this._repository);

  Future<void> call({
    required String flatId,
    required String memberId,
  }) => _repository.cancelExit(flatId: flatId, memberId: memberId);
}
