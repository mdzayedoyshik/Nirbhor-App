import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class CompleteSetupUseCase {
  final AuthRepository _repository;
  CompleteSetupUseCase(this._repository);

  Future<AuthResult> call({
    required String setupToken,
    required String name,
    required String password,
    String? deviceToken,
    String? deviceType,
  }) =>
      _repository.completeSetup(
        setupToken: setupToken,
        name: name,
        password: password,
        deviceToken: deviceToken,
        deviceType: deviceType,
      );
}
