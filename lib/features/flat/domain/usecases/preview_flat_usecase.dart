import '../entities/flat_preview_entity.dart';
import '../repositories/flat_repository.dart';

class PreviewFlatUseCase {
  final FlatRepository _repository;
  PreviewFlatUseCase(this._repository);

  Future<FlatPreviewEntity> call(String code) => _repository.previewFlat(code);
}
