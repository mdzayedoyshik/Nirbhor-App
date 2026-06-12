import '../repositories/flat_repository.dart';

class ApproveJoinRequestUseCase {
  final FlatRepository _repository;
  ApproveJoinRequestUseCase(this._repository);

  Future<void> call({
    required String flatId,
    required String requestId,
  }) => _repository.approveJoinRequest(
    flatId: flatId,
    requestId: requestId,
  );
}
