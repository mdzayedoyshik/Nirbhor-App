import 'package:equatable/equatable.dart';

class ClosePreviewMemberEntity extends Equatable {
  const ClosePreviewMemberEntity({
    required this.flatMemberId,
    required this.memberName,
    required this.walletBalanceBefore,
    required this.mealPoints,
    required this.mealCost,
    required this.fixedContribution,
    required this.householdExpenses,
    required this.totalPaid,
    required this.projectedWalletBalance,
    required this.projectedStatus,
  });

  final String flatMemberId;
  final String memberName;
  final double walletBalanceBefore;
  final double mealPoints;
  final double mealCost;
  final double fixedContribution;
  final double householdExpenses;
  final double totalPaid;
  final double projectedWalletBalance;
  final String projectedStatus;

  bool get isProjectedBalance => projectedStatus == 'balance';

  @override
  List<Object?> get props => [flatMemberId, projectedWalletBalance, projectedStatus];
}

class ClosePreviewEntity extends Equatable {
  const ClosePreviewEntity({
    required this.month,
    required this.year,
    required this.totalExpense,
    required this.totalPoints,
    required this.perPointCost,
    required this.isPoolClosed,
    required this.warnings,
    required this.memberPreviews,
  });

  final int month;
  final int year;
  final double totalExpense;
  final double totalPoints;
  final double perPointCost;
  final bool isPoolClosed;
  final List<String> warnings;
  final List<ClosePreviewMemberEntity> memberPreviews;

  bool get hasWarnings => warnings.isNotEmpty;

  @override
  List<Object?> get props => [month, year, memberPreviews];
}
