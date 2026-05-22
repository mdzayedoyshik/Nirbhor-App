import '../entities/flat_wallet_entity.dart';
import '../entities/payment_entity.dart';
import '../entities/payment_hints_entity.dart';
import '../entities/payment_request_entity.dart';
import '../entities/transaction_entity.dart';
import '../entities/verify_payment_result_entity.dart';
import '../entities/wallet_entity.dart';
import '../entities/wallet_member_summary_entity.dart';
import '../entities/wallet_summary_entity.dart';

abstract class WalletRepository {
  Future<WalletEntity> getMyWallet(String flatId);

  Future<List<WalletMemberSummaryEntity>> getAllWallets(String flatId);

  Future<FlatWalletEntity> getFlatWallet(String flatId);

  Future<WalletSummaryEntity> getWalletSummary(String flatId);

  Future<PaymentRequestEntity> createPaymentRequest({
    required String flatId,
    required String requestedTo,
    required double amount,
    String? note,
  });

  Future<List<PaymentRequestEntity>> getPaymentRequests(
    String flatId, {
    String? status,
    String? memberId,
  });

  Future<void> cancelPaymentRequest(String flatId, String requestId);

  Future<PaymentEntity> submitPayment({
    required String flatId,
    required double amount,
    required String paymentMethod,
    String? paymentRequestId,
    String? note,
  });

  Future<List<PaymentEntity>> getPayments(
    String flatId, {
    String? status,
    String? memberId,
  });

  Future<VerifyPaymentResultEntity> verifyPayment(
      String flatId, String paymentId);

  Future<void> rejectPayment(
      String flatId, String paymentId, {String? reason});

  Future<List<TransactionEntity>> getTransactions(
    String flatId, {
    String? memberId,
    String? type,
    String? category,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  });

  Future<PaymentHintsEntity> getPaymentHints(String flatId);

  Future<PaymentHintsEntity> updatePaymentHints(
    String flatId, {
    double? suggestedMealAmount,
    double? suggestedHouseholdAmount,
  });
}
