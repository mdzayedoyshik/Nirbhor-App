import 'package:equatable/equatable.dart';
import '../../../../core/enums/auth_enums.dart';

class EmailCheckResult extends Equatable {
  final AuthCheckStatus status;
  final AuthHint hint;
  final String? otpVerificationToken;

  const EmailCheckResult({
    required this.status,
    required this.hint,
    this.otpVerificationToken,
  });

  @override
  List<Object?> get props => [status, hint, otpVerificationToken];
}
