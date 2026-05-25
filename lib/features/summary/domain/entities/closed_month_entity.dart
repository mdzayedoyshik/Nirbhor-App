import 'package:equatable/equatable.dart';

class ClosedMonthEntity extends Equatable {
  const ClosedMonthEntity({
    required this.month,
    required this.year,
    required this.closedAt,
    required this.totalMealExpense,
    required this.totalMembers,
  });

  final int month;
  final int year;
  final String closedAt;
  final double totalMealExpense;
  final int totalMembers;

  @override
  List<Object?> get props => [month, year];
}
