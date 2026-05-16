import '../repositories/auth_repository.dart';

class SendDeviceTokenUseCase {
  final AuthRepository _repository;
  SendDeviceTokenUseCase(this._repository);

  Future<void> call({required String token, required String deviceType}) =>
      _repository.sendDeviceToken(token: token, deviceType: deviceType);
}
