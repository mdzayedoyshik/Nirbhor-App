import '../../domain/entities/settlement_entity.dart';

class SettlementModel extends SettlementEntity {
  const SettlementModel({
    required super.id,
    required super.memberName,
    required super.date,
    required super.mealPoints,
    required super.mealCost,
    required super.walletBalance,
    required super.fixedRefund,
    required super.finalAmount,
    required super.status,
  });

  factory SettlementModel.fromJson(Map<String, dynamic> json) => SettlementModel(
    id: json['id'] as String,
    memberName: json['member_name'] as String,
    date: json['date'] as String,
    mealPoints: (json['meal_points'] as num).toDouble(),
    mealCost: (json['meal_cost'] as num).toDouble(),
    walletBalance: (json['wallet_balance'] as num).toDouble(),
    fixedRefund: (json['fixed_refund'] as num).toDouble(),
    finalAmount: (json['final_amount'] as num).toDouble(),
    status: json['status'] as String,
  );
}
