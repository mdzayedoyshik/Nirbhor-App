import 'package:equatable/equatable.dart';

class FinalizeExitEntity extends Equatable {
  final ExitingMemberSummary exitingMember;
  final MealPoolUpdate? mealPoolUpdate;

  const FinalizeExitEntity({
    required this.exitingMember,
    this.mealPoolUpdate,
  });

  @override
  List<Object?> get props => [exitingMember, mealPoolUpdate];
}

class ExitingMemberSummary extends Equatable {
  final String flatMemberId;
  final String name;
  final double mealCostDeducted;
  final double fixedRefundCredited;
  final double finalWalletBalance;
  final double settledAmount;
  final bool managerCollected;

  const ExitingMemberSummary({
    required this.flatMemberId,
    required this.name,
    required this.mealCostDeducted,
    required this.fixedRefundCredited,
    required this.finalWalletBalance,
    required this.settledAmount,
    required this.managerCollected,
  });

  @override
  List<Object?> get props => [
        flatMemberId,
        name,
        mealCostDeducted,
        fixedRefundCredited,
        finalWalletBalance,
        settledAmount,
        managerCollected,
      ];
}

class MealPoolUpdate extends Equatable {
  final double pointsRemoved;
  final double expenseRemoved;
  final double newTotalPoints;
  final double newTotalExpense;

  const MealPoolUpdate({
    required this.pointsRemoved,
    required this.expenseRemoved,
    required this.newTotalPoints,
    required this.newTotalExpense,
  });

  @override
  List<Object?> get props => [
        pointsRemoved,
        expenseRemoved,
        newTotalPoints,
        newTotalExpense,
      ];
}
