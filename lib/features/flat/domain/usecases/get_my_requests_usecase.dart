import '../entities/join_request_entity.dart';
import '../repositories/flat_repository.dart';

class GetMyRequestsUseCase {
  final FlatRepository _repository;
  GetMyRequestsUseCase(this._repository);

  Future<List<JoinRequestEntity>> call() => _repository.getMyRequests();
}
