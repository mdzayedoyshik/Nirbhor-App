import '../../domain/entities/wallet_summary_entity.dart';
import 'payment_hints_model.dart';
import 'transaction_model.dart';

class WalletSummaryModel extends WalletSummaryEntity {
  const WalletSummaryModel({
    required super.memberName,
    required super.walletBalance,
    required super.fixedContribution,
    required super.hasPaidFixedThisMonth,
    required super.paymentHints,
    required super.suggestedTotalToPay,
    required super.pendingPaymentRequests,
    required super.recentTransactions,
  });

  factory WalletSummaryModel.fromJson(Map<String, dynamic> json) {
    final hintsJson = json['payment_hints'] as Map<String, dynamic>;
    final flatId = json['flat_id'] as String? ?? '';

    return WalletSummaryModel(
      memberName: json['member_name'] as String,
      walletBalance: (json['wallet_balance'] as num).toDouble(),
      fixedContribution: (json['fixed_contribution'] as num).toDouble(),
      hasPaidFixedThisMonth: json['has_paid_fixed_this_month'] as bool? ?? false,
      paymentHints: PaymentHintsModel(
        flatId: flatId,
        suggestedMealAmount:
            (hintsJson['suggested_meal_amount'] as num).toDouble(),
        suggestedHouseholdAmount:
            (hintsJson['suggested_household_amount'] as num).toDouble(),
        updatedAt: hintsJson['updated_at'] as String? ?? '',
      ),
      suggestedTotalToPay: (json['suggested_total_to_pay'] as num).toDouble(),
      pendingPaymentRequests: (json['pending_payment_requests'] as List)
          .map((r) => PendingRequestSummary(
                id: r['id'] as String,
                amount: (r['amount'] as num).toDouble(),
                note: r['note'] as String?,
                status: r['status'] as String? ?? 'pending',
              ))
          .toList(),
      recentTransactions: (json['recent_transactions'] as List)
          .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
