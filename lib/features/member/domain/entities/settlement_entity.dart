import 'package:equatable/equatable.dart';

class SettlementEntity extends Equatable {
  final String id;
  final String memberName;
  final String date;
  final double mealPoints;
  final double mealCost;
  final double walletBalance;
  final double fixedRefund;
  final double finalAmount;
  final String status;

  const SettlementEntity({
    required this.id,
    required this.memberName,
    required this.date,
    required this.mealPoints,
    required this.mealCost,
    required this.walletBalance,
    required this.fixedRefund,
    required this.finalAmount,
    required this.status,
  });

  bool get isPending => status == 'pending';

  // positive = flat owes member; negative = member owes flat
  bool get flatOwesMember => finalAmount > 0;

  @override
  List<Object?> get props => [
    id,
    memberName,
    date,
    mealPoints,
    mealCost,
    walletBalance,
    fixedRefund,
    finalAmount,
    status,
  ];
}
