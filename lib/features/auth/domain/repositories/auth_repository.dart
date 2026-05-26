import '../entities/auth_result.dart';
import '../entities/email_check_result.dart';
import '../entities/otp_verify_result.dart';
import '../entities/reset_password_result.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<EmailCheckResult> checkEmail(String email);

  Future<OtpVerifyResult> verifyOtp({
    required String otpVerificationToken,
    required String otp,
  });

  Future<AuthResult> login({
    required String email,
    required String password,
  });

  Future<AuthResult> completeSetup({
    required String setupToken,
    required String name,
    required String password,
  });

  // Returns otp_verification_token for the OTP screen
  Future<String> forgotPassword(String email);

  Future<ResetPasswordResult> resetPassword({
    required String setupToken,
    required String newPassword,
  });

  Future<AuthResult> googleAuth({required String idToken});

  Future<void> sendDeviceToken({
    required String token,
    required String deviceType,
  });

  Future<void> logout(String deviceToken);

  Future<UserEntity> getProfile();

  Future<UserEntity> updateProfile({required String name, String? avatarUrl});

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  Future<void> setPassword({required String newPassword});
}
