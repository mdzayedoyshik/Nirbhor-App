import 'package:equatable/equatable.dart';

class VerifyPaymentResultEntity extends Equatable {
  const VerifyPaymentResultEntity({
    required this.paymentId,
    required this.paymentStatus,
    required this.flatMemberId,
    required this.memberName,
    required this.oldBalance,
    required this.newBalance,
    required this.flatWalletOld,
    required this.flatWalletNew,
    required this.autoDeducted,
    required this.deductedAmount,
  });

  final String paymentId;
  final String paymentStatus;
  final String flatMemberId;
  final String memberName;
  final double oldBalance;
  final double newBalance;
  final double flatWalletOld;
  final double flatWalletNew;
  final bool autoDeducted;
  final double deductedAmount;

  double get netBalance => autoDeducted ? newBalance : newBalance;

  @override
  List<Object?> get props => [
        paymentId,
        paymentStatus,
        flatMemberId,
        memberName,
        oldBalance,
        newBalance,
        flatWalletOld,
        flatWalletNew,
        autoDeducted,
        deductedAmount,
      ];
}
