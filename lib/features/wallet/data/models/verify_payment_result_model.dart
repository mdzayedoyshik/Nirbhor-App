import '../../domain/entities/verify_payment_result_entity.dart';

class VerifyPaymentResultModel extends VerifyPaymentResultEntity {
  const VerifyPaymentResultModel({
    required super.paymentId,
    required super.paymentStatus,
    required super.flatMemberId,
    required super.memberName,
    required super.oldBalance,
    required super.newBalance,
    required super.flatWalletOld,
    required super.flatWalletNew,
    required super.autoDeducted,
    required super.deductedAmount,
  });

  factory VerifyPaymentResultModel.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>;
    final walletUpdate = json['wallet_update'] as Map<String, dynamic>;
    final autoFixed = json['auto_fixed_deduction'] as Map<String, dynamic>;

    return VerifyPaymentResultModel(
      paymentId: payment['id'] as String,
      paymentStatus: payment['status'] as String,
      flatMemberId: walletUpdate['flat_member_id'] as String,
      memberName: walletUpdate['member_name'] as String,
      oldBalance: (walletUpdate['old_balance'] as num).toDouble(),
      newBalance: (walletUpdate['new_balance'] as num).toDouble(),
      flatWalletOld: (walletUpdate['flat_wallet_old'] as num).toDouble(),
      flatWalletNew: (walletUpdate['flat_wallet_new'] as num).toDouble(),
      autoDeducted: autoFixed['deducted'] as bool,
      deductedAmount: (autoFixed['amount'] as num).toDouble(),
    );
  }
}
