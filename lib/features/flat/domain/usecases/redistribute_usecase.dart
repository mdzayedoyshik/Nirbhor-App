import '../repositories/flat_repository.dart';

class RedistributeUseCase {
  final FlatRepository _repository;
  RedistributeUseCase(this._repository);

  Future<void> call(String flatId) => _repository.redistribute(flatId);
}
