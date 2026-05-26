import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String createdAt;
  final bool hasPassword;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
    this.hasPassword = false,
  });

  @override
  List<Object?> get props => [id, email, name, avatarUrl, createdAt, hasPassword];
}
