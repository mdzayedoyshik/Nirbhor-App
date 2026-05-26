import '../repositories/auth_repository.dart';

class SetPasswordUseCase {
  final AuthRepository _repository;
  SetPasswordUseCase(this._repository);

  Future<void> call({required String newPassword}) =>
      _repository.setPassword(newPassword: newPassword);
}
