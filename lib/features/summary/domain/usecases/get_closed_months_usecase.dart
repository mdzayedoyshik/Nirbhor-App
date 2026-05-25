import '../entities/closed_month_entity.dart';
import '../repositories/summary_repository.dart';

class GetClosedMonthsUseCase {
  GetClosedMonthsUseCase(this._repository);
  final SummaryRepository _repository;

  Future<List<ClosedMonthEntity>> call(String flatId) =>
      _repository.getClosedMonths(flatId);
}
