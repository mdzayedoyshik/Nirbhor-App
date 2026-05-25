import '../../domain/entities/close_preview_entity.dart';

class ClosePreviewMemberModel extends ClosePreviewMemberEntity {
  const ClosePreviewMemberModel({
    required super.flatMemberId,
    required super.memberName,
    required super.walletBalanceBefore,
    required super.mealPoints,
    required super.mealCost,
    required super.fixedContribution,
    required super.householdExpenses,
    required super.totalPaid,
    required super.projectedWalletBalance,
    required super.projectedStatus,
  });

  factory ClosePreviewMemberModel.fromJson(Map<String, dynamic> json) =>
      ClosePreviewMemberModel(
        flatMemberId: json['flat_member_id'] as String,
        memberName: json['member_name'] as String? ?? '',
        walletBalanceBefore: (json['wallet_balance_before'] as num? ?? 0).toDouble(),
        mealPoints: (json['meal_points'] as num? ?? 0).toDouble(),
        mealCost: (json['meal_cost'] as num? ?? 0).toDouble(),
        fixedContribution: (json['fixed_contribution'] as num? ?? 0).toDouble(),
        householdExpenses: (json['household_expenses'] as num? ?? 0).toDouble(),
        totalPaid: (json['total_paid'] as num? ?? 0).toDouble(),
        projectedWalletBalance: (json['projected_wallet_balance'] as num? ?? 0).toDouble(),
        projectedStatus: json['projected_status'] as String? ?? 'balance',
      );
}

class ClosePreviewModel extends ClosePreviewEntity {
  const ClosePreviewModel({
    required super.month,
    required super.year,
    required super.totalExpense,
    required super.totalPoints,
    required super.perPointCost,
    required super.isPoolClosed,
    required super.warnings,
    required super.memberPreviews,
  });

  factory ClosePreviewModel.fromJson(Map<String, dynamic> json) {
    final pool = json['meal_pool'] as Map<String, dynamic>? ?? {};
    final previews = json['member_previews'] as List? ?? [];
    final warnings = (json['warnings'] as List?)
            ?.map((w) => w.toString())
            .toList() ??
        [];
    return ClosePreviewModel(
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      totalExpense: (pool['total_expense'] as num? ?? 0).toDouble(),
      totalPoints: (pool['total_points'] as num? ?? 0).toDouble(),
      perPointCost: (pool['per_point_cost'] as num? ?? 0).toDouble(),
      isPoolClosed: pool['is_closed'] as bool? ?? false,
      warnings: warnings,
      memberPreviews: previews
          .map((e) => ClosePreviewMemberModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
