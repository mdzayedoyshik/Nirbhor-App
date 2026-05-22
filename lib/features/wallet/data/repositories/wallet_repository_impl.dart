import '../../domain/entities/flat_wallet_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/payment_hints_entity.dart';
import '../../domain/entities/payment_request_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/verify_payment_result_entity.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/entities/wallet_member_summary_entity.dart';
import '../../domain/entities/wallet_summary_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({required WalletRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final WalletRemoteDataSource _dataSource;

  @override
  Future<WalletEntity> getMyWallet(String flatId) =>
      _dataSource.getMyWallet(flatId);

  @override
  Future<List<WalletMemberSummaryEntity>> getAllWallets(String flatId) =>
      _dataSource.getAllWallets(flatId);

  @override
  Future<FlatWalletEntity> getFlatWallet(String flatId) =>
      _dataSource.getFlatWallet(flatId);

  @override
  Future<WalletSummaryEntity> getWalletSummary(String flatId) =>
      _dataSource.getWalletSummary(flatId);

  @override
  Future<PaymentRequestEntity> createPaymentRequest({
    required String flatId,
    required String requestedTo,
    required double amount,
    String? note,
  }) =>
      _dataSource.createPaymentRequest(
        flatId: flatId,
        requestedTo: requestedTo,
        amount: amount,
        note: note,
      );

  @override
  Future<List<PaymentRequestEntity>> getPaymentRequests(
    String flatId, {
    String? status,
    String? memberId,
  }) =>
      _dataSource.getPaymentRequests(flatId,
          status: status, memberId: memberId);

  @override
  Future<void> cancelPaymentRequest(String flatId, String requestId) =>
      _dataSource.cancelPaymentRequest(flatId, requestId);

  @override
  Future<PaymentEntity> submitPayment({
    required String flatId,
    required double amount,
    required String paymentMethod,
    String? paymentRequestId,
    String? note,
  }) =>
      _dataSource.submitPayment(
        flatId: flatId,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentRequestId: paymentRequestId,
        note: note,
      );

  @override
  Future<List<PaymentEntity>> getPayments(
    String flatId, {
    String? status,
    String? memberId,
  }) =>
      _dataSource.getPayments(flatId, status: status, memberId: memberId);

  @override
  Future<VerifyPaymentResultEntity> verifyPayment(
          String flatId, String paymentId) =>
      _dataSource.verifyPayment(flatId, paymentId);

  @override
  Future<void> rejectPayment(String flatId, String paymentId,
          {String? reason}) =>
      _dataSource.rejectPayment(flatId, paymentId, reason: reason);

  @override
  Future<List<TransactionEntity>> getTransactions(
    String flatId, {
    String? memberId,
    String? type,
    String? category,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) =>
      _dataSource.getTransactions(
        flatId,
        memberId: memberId,
        type: type,
        category: category,
        from: from,
        to: to,
        page: page,
        limit: limit,
      );

  @override
  Future<PaymentHintsEntity> getPaymentHints(String flatId) =>
      _dataSource.getPaymentHints(flatId);

  @override
  Future<PaymentHintsEntity> updatePaymentHints(
    String flatId, {
    double? suggestedMealAmount,
    double? suggestedHouseholdAmount,
  }) =>
      _dataSource.updatePaymentHints(
        flatId,
        suggestedMealAmount: suggestedMealAmount,
        suggestedHouseholdAmount: suggestedHouseholdAmount,
      );
}
