import '../entities/otp_verify_result.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository _repository;
  VerifyOtpUseCase(this._repository);

  Future<OtpVerifyResult> call({
    required String otpVerificationToken,
    required String otp,
  }) =>
      _repository.verifyOtp(
        otpVerificationToken: otpVerificationToken,
        otp: otp,
      );
}
