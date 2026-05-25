import 'package:equatable/equatable.dart';

class MonthSummaryMemberEntity extends Equatable {
  const MonthSummaryMemberEntity({
    required this.flatMemberId,
    required this.memberName,
    required this.mealPoints,
    required this.mealCost,
    required this.fixedContribution,
    required this.householdExpenses,
    required this.totalPaid,
    required this.balance,
    required this.status,
    this.createdAt,
  });

  final String flatMemberId;
  final String memberName;
  final double mealPoints;
  final double mealCost;
  final double fixedContribution;
  final double householdExpenses;
  final double totalPaid;
  final double balance;
  final String status; // 'balance' | 'due'
  final String? createdAt;

  bool get isBalance => status == 'balance';

  @override
  List<Object?> get props => [
        flatMemberId,
        memberName,
        mealPoints,
        mealCost,
        fixedContribution,
        householdExpenses,
        totalPaid,
        balance,
        status,
      ];
}
