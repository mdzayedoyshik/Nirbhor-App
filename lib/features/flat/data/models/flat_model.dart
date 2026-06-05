import '../../domain/entities/flat_entity.dart';
import 'fixed_expense_model.dart';
import 'flat_member_model.dart';

class FlatModel extends FlatEntity {
  const FlatModel({
    required super.id,
    required super.name,
    super.address,
    required super.joinCode,
    required super.createdAt,
    required super.members,
    required super.fixedExpenses,
  });

  factory FlatModel.fromJson(Map<String, dynamic> json) => FlatModel(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String?,
    joinCode: json['join_code'] as String,
    createdAt: json['created_at'] as String,
    members: (json['members'] as List<dynamic>? ?? [])
        .map((m) => FlatMemberModel.fromJson(m as Map<String, dynamic>))
        .toList(),
    fixedExpenses: (json['fixed_expenses'] as List<dynamic>? ?? [])
        .map((e) => FixedExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
