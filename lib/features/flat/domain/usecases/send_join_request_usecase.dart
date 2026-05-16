import '../entities/join_request_entity.dart';
import '../repositories/flat_repository.dart';

class SendJoinRequestUseCase {
  final FlatRepository _repository;
  SendJoinRequestUseCase(this._repository);

  Future<JoinRequestEntity> call(String joinCode) =>
      _repository.sendJoinRequest(joinCode);
}
