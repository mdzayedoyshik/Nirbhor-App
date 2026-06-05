import '../entities/flat_entity.dart';
import '../repositories/flat_repository.dart';

class UpdateFlatUseCase {
  final FlatRepository _repository;
  UpdateFlatUseCase(this._repository);

  Future<FlatEntity> call({
    required String flatId,
    String? name,
    String? address,
  }) => _repository.updateFlat(
    flatId: flatId,
    name: name,
    address: address,
  );
}
