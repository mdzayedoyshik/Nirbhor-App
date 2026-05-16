import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;
  LoginUseCase(this._repository);

  Future<AuthResult> call({
    required String email,
    required String password,
    String? deviceToken,
    String? deviceType,
  }) =>
      _repository.login(
        email: email,
        password: password,
        deviceToken: deviceToken,
        deviceType: deviceType,
      );
}
