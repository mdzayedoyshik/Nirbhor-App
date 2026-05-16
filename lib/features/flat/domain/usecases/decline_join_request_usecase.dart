import '../repositories/flat_repository.dart';

class DeclineJoinRequestUseCase {
  final FlatRepository _repository;
  DeclineJoinRequestUseCase(this._repository);

  Future<void> call({required String flatId, required String requestId}) =>
      _repository.declineJoinRequest(flatId: flatId, requestId: requestId);
}
