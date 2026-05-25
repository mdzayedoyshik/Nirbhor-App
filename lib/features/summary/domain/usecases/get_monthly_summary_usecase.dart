import '../entities/month_summary_entity.dart';
import '../repositories/summary_repository.dart';

class GetMonthlySummaryUseCase {
  GetMonthlySummaryUseCase(this._repository);
  final SummaryRepository _repository;

  Future<MonthSummaryEntity> call(String flatId, int month, int year) =>
      _repository.getMonthlySummary(flatId, month, year);
}
