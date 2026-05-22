import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/flat_wallet_model.dart';
import '../models/payment_hints_model.dart';
import '../models/payment_model.dart';
import '../models/payment_request_model.dart';
import '../models/transaction_model.dart';
import '../models/verify_payment_result_model.dart';
import '../models/wallet_member_summary_model.dart';
import '../models/wallet_model.dart';
import '../models/wallet_summary_model.dart';

class WalletRemoteDataSource {
  WalletRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<WalletModel> getMyWallet(String flatId) async {
    final response =
        await _apiClient.get(ApiEndpoints.flatWalletMe(flatId), auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return WalletModel.fromJson(data['wallet'] as Map<String, dynamic>);
  }

  Future<List<WalletMemberSummaryModel>> getAllWallets(String flatId) async {
    final response =
        await _apiClient.get(ApiEndpoints.flatWallets(flatId), auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return (data['wallets'] as List)
        .map((w) =>
            WalletMemberSummaryModel.fromJson(w as Map<String, dynamic>))
        .toList();
  }

  Future<FlatWalletModel> getFlatWallet(String flatId) async {
    final response =
        await _apiClient.get(ApiEndpoints.flatWalletFlat(flatId), auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return FlatWalletModel.fromJson(
        data['flat_wallet'] as Map<String, dynamic>);
  }

  Future<WalletSummaryModel> getWalletSummary(String flatId) async {
    final response = await _apiClient.get(
        ApiEndpoints.flatWalletSummary(flatId),
        auth: true);
    return WalletSummaryModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  Future<PaymentRequestModel> createPaymentRequest({
    required String flatId,
    required String requestedTo,
    required double amount,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'requested_to': requestedTo,
      'amount': amount,
      'note': ?note,
    };
    final response = await _apiClient.post(
        ApiEndpoints.flatPaymentRequests(flatId), body,
        auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return PaymentRequestModel.fromJson(
        data['payment_request'] as Map<String, dynamic>);
  }

  Future<List<PaymentRequestModel>> getPaymentRequests(
    String flatId, {
    String? status,
    String? memberId,
  }) async {
    final params = <String, String>{
      'status': ?status,
      'member_id': ?memberId,
    };
    final endpoint = params.isEmpty
        ? ApiEndpoints.flatPaymentRequests(flatId)
        : '${ApiEndpoints.flatPaymentRequests(flatId)}?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final response = await _apiClient.get(endpoint, auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return (data['payment_requests'] as List)
        .map((r) =>
            PaymentRequestModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelPaymentRequest(String flatId, String requestId) =>
      _apiClient.delete(
          ApiEndpoints.flatPaymentRequest(flatId, requestId),
          auth: true);

  Future<PaymentModel> submitPayment({
    required String flatId,
    required double amount,
    required String paymentMethod,
    String? paymentRequestId,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_request_id': ?paymentRequestId,
      'note': ?note,
    };
    final response = await _apiClient.post(
        ApiEndpoints.flatPayments(flatId), body,
        auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return PaymentModel.fromJson(data['payment'] as Map<String, dynamic>);
  }

  Future<List<PaymentModel>> getPayments(
    String flatId, {
    String? status,
    String? memberId,
  }) async {
    final params = <String, String>{
      'status': ?status,
      'member_id': ?memberId,
    };
    final endpoint = params.isEmpty
        ? ApiEndpoints.flatPayments(flatId)
        : '${ApiEndpoints.flatPayments(flatId)}?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final response = await _apiClient.get(endpoint, auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return (data['payments'] as List)
        .map((p) => PaymentModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<VerifyPaymentResultModel> verifyPayment(
      String flatId, String paymentId) async {
    final response = await _apiClient.post(
        ApiEndpoints.flatPaymentVerify(flatId, paymentId), {},
        auth: true);
    return VerifyPaymentResultModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  Future<void> rejectPayment(
      String flatId, String paymentId, {String? reason}) async {
    final body = <String, dynamic>{
      'reason': ?reason,
    };
    await _apiClient.post(
        ApiEndpoints.flatPaymentReject(flatId, paymentId), body,
        auth: true);
  }

  Future<Map<String, dynamic>> getTransactionsRaw(
    String flatId, {
    String? memberId,
    String? type,
    String? category,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      'member_id': ?memberId,
      'type': ?type,
      'category': ?category,
      'from': ?from,
      'to': ?to,
    };
    final query =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final endpoint = '${ApiEndpoints.flatTransactions(flatId)}?$query';
    final response = await _apiClient.get(endpoint, auth: true);
    return response['data'] as Map<String, dynamic>;
  }

  Future<List<TransactionModel>> getTransactions(
    String flatId, {
    String? memberId,
    String? type,
    String? category,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) async {
    final data = await getTransactionsRaw(
      flatId,
      memberId: memberId,
      type: type,
      category: category,
      from: from,
      to: to,
      page: page,
      limit: limit,
    );
    return (data['transactions'] as List)
        .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentHintsModel> getPaymentHints(String flatId) async {
    final response =
        await _apiClient.get(ApiEndpoints.flatPaymentHints(flatId), auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return PaymentHintsModel.fromJson(data['hints'] as Map<String, dynamic>);
  }

  Future<PaymentHintsModel> updatePaymentHints(
    String flatId, {
    double? suggestedMealAmount,
    double? suggestedHouseholdAmount,
  }) async {
    final body = <String, dynamic>{
      'suggested_meal_amount': ?suggestedMealAmount,
      'suggested_household_amount': ?suggestedHouseholdAmount,
    };
    final response = await _apiClient.put(
        ApiEndpoints.flatPaymentHints(flatId), body,
        auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return PaymentHintsModel.fromJson(data['hints'] as Map<String, dynamic>);
  }
}
