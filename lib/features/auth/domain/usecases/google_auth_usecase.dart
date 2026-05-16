import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class GoogleAuthUseCase {
  final AuthRepository _repository;
  GoogleAuthUseCase(this._repository);

  Future<AuthResult> call({required String idToken}) =>
      _repository.googleAuth(idToken: idToken);
}
