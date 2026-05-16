import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  String? _accessToken;

  TokenService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  String? get accessToken => _accessToken;

  bool get hasAccessToken => _accessToken != null;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<bool> hasStoredSession() async {
    final token = await getRefreshToken();
    return token != null;
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    await _storage.delete(key: _refreshTokenKey);
  }
}
