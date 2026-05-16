import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/token_service.dart';
import '../models/token_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;
  final TokenService _tokenService;

  AuthRemoteDataSource({
    required ApiClient apiClient,
    required TokenService tokenService,
  })  : _apiClient = apiClient,
        _tokenService = tokenService;

  Future<Map<String, dynamic>> checkEmail(String email) =>
      _apiClient.post(ApiEndpoints.checkEmail, {'email': email});

  Future<Map<String, dynamic>> verifyOtp({
    required String otpVerificationToken,
    required String otp,
  }) =>
      _apiClient.post(ApiEndpoints.verifyOtp, {
        'otp_verification_token': otpVerificationToken,
        'otp': otp,
      });

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? deviceToken,
    String? deviceType,
  }) {
    final body = <String, dynamic>{'email': email, 'password': password};
    if (deviceToken != null) body['device_token'] = deviceToken;
    if (deviceType != null) body['device_type'] = deviceType;
    return _apiClient.post(ApiEndpoints.login, body);
  }

  Future<Map<String, dynamic>> completeSetup({
    required String setupToken,
    required String name,
    required String password,
    String? deviceToken,
    String? deviceType,
  }) {
    final body = <String, dynamic>{
      'setup_token': setupToken,
      'name': name,
      'password': password,
    };
    if (deviceToken != null) body['device_token'] = deviceToken;
    if (deviceType != null) body['device_type'] = deviceType;
    return _apiClient.post(ApiEndpoints.completeSetup, body);
  }

  Future<Map<String, dynamic>> forgotPassword(String email) =>
      _apiClient.post(ApiEndpoints.forgotPassword, {'email': email});

  Future<Map<String, dynamic>> resetPassword({
    required String setupToken,
    required String newPassword,
  }) =>
      _apiClient.post(ApiEndpoints.resetPassword, {
        'setup_token': setupToken,
        'new_password': newPassword,
      });

  Future<Map<String, dynamic>> googleAuth({
    required String idToken,
    String? deviceToken,
    String? deviceType,
  }) {
    final body = <String, dynamic>{'id_token': idToken};
    if (deviceToken != null) body['device_token'] = deviceToken;
    if (deviceType != null) body['device_type'] = deviceType;
    return _apiClient.post(ApiEndpoints.googleAuth, body);
  }

  Future<void> logout(String deviceToken) => _apiClient.post(
        ApiEndpoints.logout,
        {'device_token': deviceToken},
        auth: true,
      );

  Future<Map<String, dynamic>> getProfile() =>
      _apiClient.get(ApiEndpoints.profile, auth: true);

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? avatarUrl,
  }) {
    final body = <String, dynamic>{'name': name};
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    return _apiClient.put(ApiEndpoints.profile, body, auth: true);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) =>
      _apiClient.put(
        ApiEndpoints.changePassword,
        {'old_password': oldPassword, 'new_password': newPassword},
        auth: true,
      );

  Future<void> saveTokens(TokenModel tokens) => _tokenService.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

  Future<void> clearTokens() => _tokenService.clearTokens();
}
