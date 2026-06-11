import '../entities/flat_entity.dart';
import '../repositories/flat_repository.dart';

class CreateFlatUseCase {
  final FlatRepository _repository;
  CreateFlatUseCase(this._repository);

  Future<FlatEntity> call({
    required String name,
    String? address,
    String? timezone,
  }) =>
      _repository.createFlat(name: name, address: address, timezone: timezone);
}
