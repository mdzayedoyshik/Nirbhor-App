import '../repositories/auth_repository.dart';

class ChangePasswordUseCase {
  final AuthRepository _repository;
  ChangePasswordUseCase(this._repository);

  Future<void> call({
    required String oldPassword,
    required String newPassword,
  }) =>
      _repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
}
