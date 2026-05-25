import 'package:equatable/equatable.dart';

class CategorySummary extends Equatable {
  const CategorySummary({
    required this.count,
    required this.total,
    required this.approvedCount,
    required this.approvedTotal,
  });

  final int count;
  final double total;
  final int approvedCount;
  final double approvedTotal;

  @override
  List<Object?> get props => [count, total, approvedCount, approvedTotal];
}

class ExpenseSummaryEntity extends Equatable {
  const ExpenseSummaryEntity({
    required this.month,
    required this.year,
    required this.meal,
    required this.household,
    required this.fixed,
    required this.grandTotalApproved,
  });

  final int month;
  final int year;
  final CategorySummary meal;
  final CategorySummary household;
  final CategorySummary fixed;
  final double grandTotalApproved;

  @override
  List<Object?> get props =>
      [month, year, meal, household, fixed, grandTotalApproved];
}
