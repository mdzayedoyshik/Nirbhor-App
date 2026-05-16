import '../entities/join_request_entity.dart';
import '../repositories/flat_repository.dart';

class GetJoinRequestsUseCase {
  final FlatRepository _repository;
  GetJoinRequestsUseCase(this._repository);

  Future<List<JoinRequestEntity>> call(String flatId) =>
      _repository.getJoinRequests(flatId);
}
