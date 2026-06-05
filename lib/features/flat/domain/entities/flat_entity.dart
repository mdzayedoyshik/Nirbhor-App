import 'package:equatable/equatable.dart';

import 'fixed_expense_entity.dart';
import 'flat_member_entity.dart';

class FlatEntity extends Equatable {
  final String id;
  final String name;
  final String? address;
  final String joinCode;
  final String createdAt;
  final List<FlatMemberEntity> members;
  final List<FixedExpenseEntity> fixedExpenses;

  const FlatEntity({
    required this.id,
    required this.name,
    this.address,
    required this.joinCode,
    required this.createdAt,
    required this.members,
    required this.fixedExpenses,
  });

  List<FlatMemberEntity> get activeMembers =>
      members.where((m) => m.isActive).toList();

  double get totalFixedExpenses =>
      fixedExpenses.fold(0, (sum, e) => sum + e.amount);

  FlatMemberEntity? memberByUserId(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
    id,
    name,
    address,
    joinCode,
    createdAt,
    members,
    fixedExpenses,
  ];
}
