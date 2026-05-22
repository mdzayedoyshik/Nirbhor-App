import '../../domain/entities/expense_summary_entity.dart';

class CategorySummaryModel extends CategorySummary {
  const CategorySummaryModel({
    required super.count,
    required super.total,
    required super.approvedCount,
    required super.approvedTotal,
  });

  factory CategorySummaryModel.fromJson(Map<String, dynamic> json) =>
      CategorySummaryModel(
        count: (json['count'] as num).toInt(),
        total: (json['total'] as num).toDouble(),
        approvedCount: (json['approved_count'] as num).toInt(),
        approvedTotal: (json['approved_total'] as num).toDouble(),
      );
}

class ExpenseSummaryModel extends ExpenseSummaryEntity {
  const ExpenseSummaryModel({
    required super.month,
    required super.year,
    required super.meal,
    required super.household,
    required super.fixed,
    required super.grandTotalApproved,
  });

  factory ExpenseSummaryModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>;
    return ExpenseSummaryModel(
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      meal: CategorySummaryModel.fromJson(
          summary['meal'] as Map<String, dynamic>),
      household: CategorySummaryModel.fromJson(
          summary['household'] as Map<String, dynamic>),
      fixed: CategorySummaryModel.fromJson(
          summary['fixed'] as Map<String, dynamic>),
      grandTotalApproved:
          (summary['grand_total_approved'] as num).toDouble(),
    );
  }
}
