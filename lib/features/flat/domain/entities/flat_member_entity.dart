import 'package:equatable/equatable.dart';

class FlatMemberEntity extends Equatable {
  final String flatMemberId;
  final String userId;
  final String name;
  final String email;
  final String? photoUrl;
  final String role; // 'manager' | 'co-manager' | 'member'
  final double fixedContribution;
  final bool isActive;
  final String joinedAt;

  const FlatMemberEntity({
    required this.flatMemberId,
    required this.userId,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.fixedContribution,
    required this.isActive,
    required this.joinedAt,
  });

  bool get isManager => role == 'manager';
  bool get isCoManager => role == 'co-manager';
  bool get canManage => isManager || isCoManager;

  @override
  List<Object?> get props => [
    flatMemberId,
    userId,
    name,
    email,
    photoUrl,
    role,
    fixedContribution,
    isActive,
    joinedAt,
  ];
}
