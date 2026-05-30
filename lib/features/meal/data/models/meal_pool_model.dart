import '../../domain/entities/meal_pool_entity.dart';

class MealPoolModel extends MealPoolEntity {
  const MealPoolModel({
    required super.month,
    required super.year,
    required super.totalExpense,
    required super.totalPoints,
    required super.perPointCost,
    required super.isClosed,
    required super.memberBreakdown,
  });

  factory MealPoolModel.fromJson(Map<String, dynamic> json) {
    final breakdown = (json['member_breakdown'] as List? ?? [])
        .map((e) => _parseMember(e as Map<String, dynamic>))
        .toList();

    return MealPoolModel(
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0,
      totalPoints: (json['total_points'] as num?)?.toDouble() ?? 0,
      perPointCost: (json['per_point_cost'] as num?)?.toDouble() ?? 0,
      isClosed: json['is_closed'] as bool? ?? false,
      memberBreakdown: breakdown,
    );
  }

  static MealPoolMemberEntity _parseMember(Map<String, dynamic> m) =>
      MealPoolMemberEntity(
        flatMemberId: m['flat_member_id'] as String,
        memberName: m['member_name'] as String? ?? '',
        totalPoints: (m['total_points'] as num?)?.toDouble() ?? 0,
        estimatedMealCost: (m['estimated_meal_cost'] as num?)?.toDouble() ?? 0,
      );
}
