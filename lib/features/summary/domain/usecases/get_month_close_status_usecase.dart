import '../entities/month_close_status_entity.dart';
import '../repositories/summary_repository.dart';

class GetMonthCloseStatusUseCase {
  GetMonthCloseStatusUseCase(this._repository);
  final SummaryRepository _repository;

  Future<MonthCloseStatusEntity> call(String flatId) =>
      _repository.getMonthCloseStatus(flatId);
}
