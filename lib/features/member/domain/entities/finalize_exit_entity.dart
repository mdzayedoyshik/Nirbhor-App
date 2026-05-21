import 'package:equatable/equatable.dart';

class FinalizeExitEntity extends Equatable {
  final ExitingMemberSummary exitingMember;
  final List<MemberDeduction> remainingMemberDeductions;
  final MealPoolUpdate? mealPoolUpdate;

  const FinalizeExitEntity({
    required this.exitingMember,
    required this.remainingMemberDeductions,
    this.mealPoolUpdate,
  });

  @override
  List<Object?> get props => [exitingMember, remainingMemberDeductions, mealPoolUpdate];
}

class ExitingMemberSummary extends Equatable {
  final String flatMemberId;
  final String name;
  final double mealCostDeducted;
  final double fixedRefundCredited;
  final double finalWalletBalance;

  const ExitingMemberSummary({
    required this.flatMemberId,
    required this.name,
    required this.mealCostDeducted,
    required this.fixedRefundCredited,
    required this.finalWalletBalance,
  });

  @override
  List<Object?> get props => [flatMemberId, name, mealCostDeducted, fixedRefundCredited, finalWalletBalance];
}

class MemberDeduction extends Equatable {
  final String flatMemberId;
  final String name;
  final double deducted;
  final double newWalletBalance;

  const MemberDeduction({
    required this.flatMemberId,
    required this.name,
    required this.deducted,
    required this.newWalletBalance,
  });

  @override
  List<Object?> get props => [flatMemberId, name, deducted, newWalletBalance];
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
  List<Object?> get props => [pointsRemoved, expenseRemoved, newTotalPoints, newTotalExpense];
}
