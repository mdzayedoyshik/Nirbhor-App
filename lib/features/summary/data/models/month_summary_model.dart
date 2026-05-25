import '../../domain/entities/month_summary_entity.dart';
import '../../domain/entities/month_summary_member_entity.dart';

class MonthSummaryMemberModel extends MonthSummaryMemberEntity {
  const MonthSummaryMemberModel({
    required super.flatMemberId,
    required super.memberName,
    required super.mealPoints,
    required super.mealCost,
    required super.fixedContribution,
    required super.householdExpenses,
    required super.totalPaid,
    required super.balance,
    required super.status,
    super.createdAt,
  });

  factory MonthSummaryMemberModel.fromJson(Map<String, dynamic> json) =>
      MonthSummaryMemberModel(
        flatMemberId: json['flat_member_id'] as String,
        memberName: json['member_name'] as String? ?? '',
        mealPoints: (json['total_meal_points'] as num).toDouble(),
        mealCost: (json['meal_cost'] as num).toDouble(),
        fixedContribution: (json['fixed_contribution'] as num).toDouble(),
        householdExpenses: (json['household_expenses'] as num).toDouble(),
        totalPaid: (json['total_paid'] as num).toDouble(),
        balance: (json['balance'] as num).toDouble(),
        status: json['status'] as String? ?? 'balance',
        createdAt: json['created_at'] as String?,
      );
}

class MonthSummaryModel extends MonthSummaryEntity {
  const MonthSummaryModel({
    required super.month,
    required super.year,
    required super.isClosed,
    super.closedAt,
    required super.totalExpense,
    required super.totalPoints,
    required super.perPointCost,
    required super.members,
  });

  factory MonthSummaryModel.fromJson(Map<String, dynamic> json) {
    final pool = json['meal_pool'] as Map<String, dynamic>? ?? {};
    final summaries = json['summaries'] as List? ?? [];
    return MonthSummaryModel(
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      isClosed: json['is_closed'] as bool? ?? false,
      closedAt: json['closed_at'] as String?,
      totalExpense: (pool['total_expense'] as num? ?? 0).toDouble(),
      totalPoints: (pool['total_points'] as num? ?? 0).toDouble(),
      perPointCost: (pool['per_point_cost'] as num? ?? 0).toDouble(),
      members: summaries
          .map((e) => MonthSummaryMemberModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
