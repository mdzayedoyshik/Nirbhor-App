import 'package:equatable/equatable.dart';

import 'month_summary_member_entity.dart';

class MonthSummaryEntity extends Equatable {
  const MonthSummaryEntity({
    required this.month,
    required this.year,
    required this.isClosed,
    this.closedAt,
    required this.totalExpense,
    required this.totalPoints,
    required this.perPointCost,
    required this.members,
  });

  final int month;
  final int year;
  final bool isClosed;
  final String? closedAt;
  final double totalExpense;
  final double totalPoints;
  final double perPointCost;
  final List<MonthSummaryMemberEntity> members;

  @override
  List<Object?> get props => [month, year, isClosed, totalExpense, members];
}
