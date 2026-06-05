import '../../domain/entities/flat_member_entity.dart';

class FlatMemberModel extends FlatMemberEntity {
  const FlatMemberModel({
    required super.flatMemberId,
    required super.userId,
    required super.name,
    required super.email,
    super.photoUrl,
    required super.role,
    required super.fixedContribution,
    required super.isActive,
    required super.joinedAt,
  });

  factory FlatMemberModel.fromJson(Map<String, dynamic> json) =>
      FlatMemberModel(
        flatMemberId: json['flat_member_id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        photoUrl: json['avatar_url'] as String?,
        role: json['role'] as String,
        fixedContribution: (json['fixed_contribution'] as num).toDouble(),
        isActive: json['is_active'] as bool? ?? true,
        joinedAt: json['joined_at'] as String? ?? '',
      );
}
