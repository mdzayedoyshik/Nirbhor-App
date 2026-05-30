import '../../domain/entities/closed_month_entity.dart';

class ClosedMonthModel extends ClosedMonthEntity {
  const ClosedMonthModel({
    required super.month,
    required super.year,
    required super.closedAt,
    required super.totalMealExpense,
    required super.totalMembers,
  });

  factory ClosedMonthModel.fromJson(Map<String, dynamic> json) =>
      ClosedMonthModel(
        month: (json['month'] as num).toInt(),
        year: (json['year'] as num).toInt(),
        closedAt: json['closed_at'] as String? ?? '',
        totalMealExpense: (json['total_meal_expense'] as num? ?? 0).toDouble(),
        totalMembers: (json['total_members'] as num? ?? 0).toInt(),
      );
}
