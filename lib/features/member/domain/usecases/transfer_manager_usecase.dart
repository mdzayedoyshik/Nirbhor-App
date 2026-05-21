import '../repositories/member_repository.dart';

class TransferManagerUseCase {
  final MemberRepository _repository;
  TransferManagerUseCase(this._repository);

  Future<void> call({
    required String flatId,
    required String newManagerId,
  }) => _repository.transferManager(flatId: flatId, newManagerId: newManagerId);
}
