import '../../../../core/enums/auth_enums.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/email_check_result.dart';
import '../../domain/entities/otp_verify_result.dart';
import '../../domain/entities/reset_password_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/token_model.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl({required AuthRemoteDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<EmailCheckResult> checkEmail(String email) async {
    final response = await _dataSource.checkEmail(email);
    final data = response['data'] as Map<String, dynamic>;

    final status = (data['status'] as String) == 'otp_sent'
        ? AuthCheckStatus.otpSent
        : AuthCheckStatus.passwordRequired;

    final AuthHint hint;
    switch (data['hint'] as String) {
      case 'new_user':
        hint = AuthHint.newUser;
        break;
      case 'google_no_password':
        hint = AuthHint.googleNoPassword;
        break;
      default:
        hint = AuthHint.existingPassword;
    }

    return EmailCheckResult(
      status: status,
      hint: hint,
      otpVerificationToken: data['otp_verification_token'] as String?,
    );
  }

  @override
  Future<OtpVerifyResult> verifyOtp({
    required String otpVerificationToken,
    required String otp,
  }) async {
    final response = await _dataSource.verifyOtp(
      otpVerificationToken: otpVerificationToken,
      otp: otp,
    );
    final data = response['data'] as Map<String, dynamic>;
    return OtpVerifyResult(setupToken: data['setup_token'] as String);
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    String? deviceToken,
    String? deviceType,
  }) async {
    final response = await _dataSource.login(
      email: email,
      password: password,
      deviceToken: deviceToken,
      deviceType: deviceType,
    );
    return _parseAuthResult(response);
  }

  @override
  Future<AuthResult> completeSetup({
    required String setupToken,
    required String name,
    required String password,
    String? deviceToken,
    String? deviceType,
  }) async {
    final response = await _dataSource.completeSetup(
      setupToken: setupToken,
      name: name,
      password: password,
      deviceToken: deviceToken,
      deviceType: deviceType,
    );
    return _parseAuthResult(response);
  }

  @override
  Future<String> forgotPassword(String email) async {
    final response = await _dataSource.forgotPassword(email);
    final data = response['data'] as Map<String, dynamic>;
    return data['otp_verification_token'] as String;
  }

  @override
  Future<ResetPasswordResult> resetPassword({
    required String setupToken,
    required String newPassword,
  }) async {
    final response = await _dataSource.resetPassword(
      setupToken: setupToken,
      newPassword: newPassword,
    );
    final data = response['data'] as Map<String, dynamic>?;

    if (data != null && data.containsKey('tokens')) {
      final tokens =
          TokenModel.fromJson(data['tokens'] as Map<String, dynamic>);
      await _dataSource.saveTokens(tokens);
      return ResetPasswordResult(tokens: tokens);
    }
    return const ResetPasswordResult();
  }

  @override
  Future<AuthResult> googleAuth({
    required String idToken,
    String? deviceToken,
    String? deviceType,
  }) async {
    final response = await _dataSource.googleAuth(
      idToken: idToken,
      deviceToken: deviceToken,
      deviceType: deviceType,
    );
    return _parseAuthResult(response);
  }

  @override
  Future<void> logout(String deviceToken) async {
    await _dataSource.logout(deviceToken);
    await _dataSource.clearTokens();
  }

  @override
  Future<UserEntity> getProfile() async {
    final response = await _dataSource.getProfile();
    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<UserEntity> updateProfile({
    required String name,
    String? avatarUrl,
  }) async {
    final response =
        await _dataSource.updateProfile(name: name, avatarUrl: avatarUrl);
    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) =>
      _dataSource.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

  Future<AuthResult> _parseAuthResult(Map<String, dynamic> response) async {
    final data = response['data'] as Map<String, dynamic>;
    final tokens =
        TokenModel.fromJson(data['tokens'] as Map<String, dynamic>);
    final user =
        UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await _dataSource.saveTokens(tokens);
    return AuthResult(tokens: tokens, user: user);
  }
}
