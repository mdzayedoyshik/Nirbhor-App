import '../../domain/entities/close_preview_entity.dart';
import '../../domain/entities/closed_month_entity.dart';
import '../../domain/entities/month_close_status_entity.dart';
import '../../domain/entities/month_summary_entity.dart';
import '../../domain/repositories/summary_repository.dart';
import '../datasources/summary_remote_datasource.dart';

class SummaryRepositoryImpl implements SummaryRepository {
  SummaryRepositoryImpl({required SummaryRemoteDataSource dataSource})
      : _dataSource = dataSource;
  final SummaryRemoteDataSource _dataSource;

  @override
  Future<MonthSummaryEntity> getMonthlySummary(
          String flatId, int month, int year) =>
      _dataSource.getMonthlySummary(flatId, month, year);

  @override
  Future<ClosePreviewEntity> getClosePreview(String flatId) =>
      _dataSource.getClosePreview(flatId);

  @override
  Future<void> closeMonth(String flatId, int month, int year,
          {bool force = false}) =>
      _dataSource.closeMonth(flatId, month, year, force);

  @override
  Future<List<ClosedMonthEntity>> getClosedMonths(String flatId) =>
      _dataSource.getClosedMonths(flatId);

  @override
  Future<MonthCloseStatusEntity> getMonthCloseStatus(String flatId) =>
      _dataSource.getMonthCloseStatus(flatId);
}
