import '../../domain/entities/finalize_exit_entity.dart';

class FinalizeExitModel extends FinalizeExitEntity {
  const FinalizeExitModel({
    required super.exitingMember,
    super.mealPoolUpdate,
  });

  factory FinalizeExitModel.fromJson(Map<String, dynamic> json) {
    final exitingJson = json['exiting_member'] as Map<String, dynamic>;
    final poolJson = json['meal_pool_update'] as Map<String, dynamic>?;

    return FinalizeExitModel(
      exitingMember: ExitingMemberSummary(
        flatMemberId: exitingJson['flat_member_id'] as String,
        name: exitingJson['name'] as String,
        mealCostDeducted: (exitingJson['meal_cost_deducted'] as num).toDouble(),
        fixedRefundCredited:
            (exitingJson['fixed_refund_credited'] as num).toDouble(),
        finalWalletBalance:
            (exitingJson['final_wallet_balance'] as num).toDouble(),
        settledAmount: (exitingJson['settled_amount'] as num? ?? 0).toDouble(),
        managerCollected: exitingJson['manager_collected'] as bool? ?? false,
      ),
      mealPoolUpdate: poolJson == null
          ? null
          : MealPoolUpdate(
              pointsRemoved: (poolJson['points_removed'] as num).toDouble(),
              expenseRemoved: (poolJson['expense_removed'] as num).toDouble(),
              newTotalPoints: (poolJson['new_total_points'] as num).toDouble(),
              newTotalExpense: (poolJson['new_total_expense'] as num).toDouble(),
            ),
    );
  }
}
