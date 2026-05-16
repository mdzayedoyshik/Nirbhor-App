import '../repositories/flat_repository.dart';

class DeleteFlatUseCase {
  final FlatRepository _repository;
  DeleteFlatUseCase(this._repository);

  Future<void> call(String flatId) => _repository.deleteFlat(flatId);
}
