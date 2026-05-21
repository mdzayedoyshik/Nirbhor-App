import '../../../flat/domain/entities/flat_member_entity.dart';
import '../repositories/member_repository.dart';

class GetMembersUseCase {
  final MemberRepository _repository;
  GetMembersUseCase(this._repository);

  Future<List<FlatMemberEntity>> call(String flatId) =>
      _repository.getMembers(flatId);
}
