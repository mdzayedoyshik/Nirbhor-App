import '../repositories/member_repository.dart';

class AcknowledgeExitUseCase {
  final MemberRepository _repository;
  AcknowledgeExitUseCase(this._repository);

  Future<void> call() => _repository.acknowledgeExit();
}
