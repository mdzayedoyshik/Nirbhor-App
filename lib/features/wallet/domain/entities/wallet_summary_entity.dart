import 'package:equatable/equatable.dart';

import 'payment_hints_entity.dart';
import 'transaction_entity.dart';

class PendingRequestSummary extends Equatable {
  const PendingRequestSummary({
    required this.id,
    required this.amount,
    this.note,
  });

  final String id;
  final double amount;
  final String? note;

  @override
  List<Object?> get props => [id, amount, note];
}

class WalletSummaryEntity extends Equatable {
  const WalletSummaryEntity({
    required this.memberName,
    required this.walletBalance,
    required this.fixedContribution,
    required this.hasPaidFixedThisMonth,
    required this.paymentHints,
    required this.suggestedTotalToPay,
    required this.pendingPaymentRequests,
    required this.recentTransactions,
  });

  final String memberName;
  final double walletBalance;
  final double fixedContribution;
  final bool hasPaidFixedThisMonth;
  final PaymentHintsEntity paymentHints;
  final double suggestedTotalToPay;
  final List<PendingRequestSummary> pendingPaymentRequests;
  final List<TransactionEntity> recentTransactions;

  bool get isNegative => walletBalance < 0;
  bool get hasPendingRequests => pendingPaymentRequests.isNotEmpty;

  @override
  List<Object?> get props => [
        memberName,
        walletBalance,
        fixedContribution,
        hasPaidFixedThisMonth,
        paymentHints,
        suggestedTotalToPay,
        pendingPaymentRequests,
        recentTransactions,
      ];
}
