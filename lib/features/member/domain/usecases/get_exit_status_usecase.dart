import '../entities/exit_status_entity.dart';
import '../repositories/member_repository.dart';

class GetExitStatusUseCase {
  final MemberRepository _repository;
  GetExitStatusUseCase(this._repository);

  Future<ExitStatusEntity> call() => _repository.getExitStatus();
}
