import '../repositories/member_repository.dart';

class GetPendingExitsUseCase {
  final MemberRepository _repository;
  GetPendingExitsUseCase(this._repository);

  Future<List<Map<String, dynamic>>> call(String flatId) =>
      _repository.getPendingExits(flatId);
}
