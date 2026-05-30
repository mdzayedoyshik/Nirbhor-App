import '../repositories/summary_repository.dart';

class CloseMonthUseCase {
  CloseMonthUseCase(this._repository);
  final SummaryRepository _repository;

  Future<void> call(String flatId, int month, int year, {bool force = false}) =>
      _repository.closeMonth(flatId, month, year, force: force);
}
