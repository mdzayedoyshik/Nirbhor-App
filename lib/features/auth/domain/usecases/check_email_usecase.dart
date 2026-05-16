import '../entities/email_check_result.dart';
import '../repositories/auth_repository.dart';

class CheckEmailUseCase {
  final AuthRepository _repository;
  CheckEmailUseCase(this._repository);

  Future<EmailCheckResult> call(String email) => _repository.checkEmail(email);
}
