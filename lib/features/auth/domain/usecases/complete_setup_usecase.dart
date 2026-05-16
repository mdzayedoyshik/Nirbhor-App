import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class CompleteSetupUseCase {
  final AuthRepository _repository;
  CompleteSetupUseCase(this._repository);

  Future<AuthResult> call({
    required String setupToken,
    required String name,
    required String password,
  }) =>
      _repository.completeSetup(
        setupToken: setupToken,
        name: name,
        password: password,
      );
}
