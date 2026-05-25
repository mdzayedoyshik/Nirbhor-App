import '../entities/close_preview_entity.dart';
import '../entities/closed_month_entity.dart';
import '../entities/month_summary_entity.dart';

abstract class SummaryRepository {
  Future<MonthSummaryEntity> getMonthlySummary(String flatId, int month, int year);
  Future<ClosePreviewEntity> getClosePreview(String flatId);
  Future<void> closeMonth(String flatId, int month, int year, {bool force = false});
  Future<List<ClosedMonthEntity>> getClosedMonths(String flatId);
}
