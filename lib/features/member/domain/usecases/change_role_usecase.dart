import '../repositories/member_repository.dart';

class ChangeRoleUseCase {
  final MemberRepository _repository;
  ChangeRoleUseCase(this._repository);

  Future<void> call({
    required String flatId,
    required String memberId,
    required String role,
  }) => _repository.changeRole(flatId: flatId, memberId: memberId, role: role);
}
