import '../repositories/flat_repository.dart';

class CancelJoinRequestUseCase {
  final FlatRepository _repository;
  CancelJoinRequestUseCase(this._repository);

  Future<void> call(String requestId) =>
      _repository.cancelJoinRequest(requestId);
}
