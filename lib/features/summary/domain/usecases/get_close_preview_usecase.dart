import '../entities/close_preview_entity.dart';
import '../repositories/summary_repository.dart';

class GetClosePreviewUseCase {
  GetClosePreviewUseCase(this._repository);
  final SummaryRepository _repository;

  Future<ClosePreviewEntity> call(String flatId) =>
      _repository.getClosePreview(flatId);
}
