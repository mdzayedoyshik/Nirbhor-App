import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository _repository;
  UpdateProfileUseCase(this._repository);

  Future<UserEntity> call({required String name, String? avatarUrl}) =>
      _repository.updateProfile(name: name, avatarUrl: avatarUrl);
}
