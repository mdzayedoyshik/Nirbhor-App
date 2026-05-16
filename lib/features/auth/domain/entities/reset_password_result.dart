import 'package:equatable/equatable.dart';
import 'token_entity.dart';

class ResetPasswordResult extends Equatable {
  // Only present when scope is set_password (google_no_password flow → auto-login)
  final TokenEntity? tokens;

  const ResetPasswordResult({this.tokens});

  bool get isAutoLogin => tokens != null;

  @override
  List<Object?> get props => [tokens];
}
