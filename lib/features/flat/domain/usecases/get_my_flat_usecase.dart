import '../entities/flat_entity.dart';
import '../repositories/flat_repository.dart';

class GetMyFlatUseCase {
  final FlatRepository _repository;
  GetMyFlatUseCase(this._repository);

  Future<FlatEntity> call() => _repository.getMyFlat();
}
