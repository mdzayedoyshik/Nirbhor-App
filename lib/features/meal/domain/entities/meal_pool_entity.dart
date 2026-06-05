import 'package:equatable/equatable.dart';

class MealPoolMemberEntity extends Equatable {
  const MealPoolMemberEntity({
    required this.flatMemberId,
    required this.memberName,
    this.photoUrl,
    required this.totalPoints,
    required this.estimatedMealCost,
  });

  final String flatMemberId;
  final String memberName;
  final String? photoUrl;
  final double totalPoints;
  final double estimatedMealCost;

  @override
  List<Object?> get props =>
      [flatMemberId, memberName, photoUrl, totalPoints, estimatedMealCost];
}

class MealPoolEntity extends Equatable {
  const MealPoolEntity({
    required this.month,
    required this.year,
    required this.totalExpense,
    required this.totalPoints,
    required this.perPointCost,
    required this.isClosed,
    required this.memberBreakdown,
  });

  final int month;
  final int year;
  final double totalExpense;
  final double totalPoints;
  final double perPointCost;
  final bool isClosed;
  final List<MealPoolMemberEntity> memberBreakdown;

  @override
  List<Object?> get props => [
        month,
        year,
        totalExpense,
        totalPoints,
        perPointCost,
        isClosed,
        memberBreakdown,
      ];
}
