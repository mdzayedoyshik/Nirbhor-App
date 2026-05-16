import 'package:equatable/equatable.dart';
import 'token_entity.dart';
import 'user_entity.dart';

class AuthResult extends Equatable {
  final TokenEntity tokens;
  final UserEntity user;

  const AuthResult({required this.tokens, required this.user});

  @override
  List<Object?> get props => [tokens, user];
}
