import '../entities/reset_password_result.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository _repository;
  ResetPasswordUseCase(this._repository);

  Future<ResetPasswordResult> call({
    required String setupToken,
    required String newPassword,
  }) =>
      _repository.resetPassword(
        setupToken: setupToken,
        newPassword: newPassword,
      );
}
