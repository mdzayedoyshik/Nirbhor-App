import '../../../../core/cache/cache_service.dart';
import '../../../../core/cache/cacheable.dart';
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

/// Cache-aware wallet datasource. GET methods use [cacheable] (remote-first,
/// fall back to last-cached on NetworkException); write methods always hit the
/// network and are gated when offline at the UI layer.
class WalletRemoteDataSource {
  WalletRemoteDataSource({
    required ApiClient apiClient,
    required CacheService cache,
  })  : _apiClient = apiClient,
        _cache = cache;

  final ApiClient _apiClient;
  final CacheService _cache;

  Future<WalletModel> getMyWallet(String flatId) => cacheable(
        cache: _cache,
        key: 'wallet_me:$flatId',
        fetchRaw: () =>
            _apiClient.get(ApiEndpoints.flatWalletMe(flatId), auth: true),
        parse: (json) => WalletModel.fromJson(
            (json['data'] as Map<String, dynamic>)['wallet']
                as Map<String, dynamic>),
      );

  Future<List<WalletMemberSummaryModel>> getAllWallets(String flatId) =>
      cacheable(
        cache: _cache,
        key: 'wallets_all:$flatId',
        fetchRaw: () =>
            _apiClient.get(ApiEndpoints.flatWallets(flatId), auth: true),
        parse: (json) =>
            ((json['data'] as Map<String, dynamic>)['wallets'] as List)
                .map((w) =>
                    WalletMemberSummaryModel.fromJson(w as Map<String, dynamic>))
                .toList(),
      );

  Future<FlatWalletModel> getFlatWallet(String flatId) => cacheable(
        cache: _cache,
        key: 'wallet_flat:$flatId',
        fetchRaw: () =>
            _apiClient.get(ApiEndpoints.flatWalletFlat(flatId), auth: true),
        parse: (json) => FlatWalletModel.fromJson(
            (json['data'] as Map<String, dynamic>)['flat_wallet']
                as Map<String, dynamic>),
      );

  Future<WalletSummaryModel> getWalletSummary(String flatId) => cacheable(
        cache: _cache,
        key: 'wallet_summary:$flatId',
        fetchRaw: () =>
            _apiClient.get(ApiEndpoints.flatWalletSummary(flatId), auth: true),
        parse: (json) =>
            WalletSummaryModel.fromJson(json['data'] as Map<String, dynamic>),
      );

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
  }) {
    final params = <String, String>{
      'status': ?status,
      'member_id': ?memberId,
    };
    final endpoint = params.isEmpty
        ? ApiEndpoints.flatPaymentRequests(flatId)
        : '${ApiEndpoints.flatPaymentRequests(flatId)}?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    return cacheable(
      cache: _cache,
      key: 'payment_requests:$flatId:${status ?? ''}:${memberId ?? ''}',
      fetchRaw: () => _apiClient.get(endpoint, auth: true),
      parse: (json) =>
          ((json['data'] as Map<String, dynamic>)['payment_requests'] as List)
              .map((r) => PaymentRequestModel.fromJson(r as Map<String, dynamic>))
              .toList(),
    );
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
  }) {
    final params = <String, String>{
      'status': ?status,
      'member_id': ?memberId,
    };
    final endpoint = params.isEmpty
        ? ApiEndpoints.flatPayments(flatId)
        : '${ApiEndpoints.flatPayments(flatId)}?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    return cacheable(
      cache: _cache,
      key: 'payments:$flatId:${status ?? ''}:${memberId ?? ''}',
      fetchRaw: () => _apiClient.get(endpoint, auth: true),
      parse: (json) =>
          ((json['data'] as Map<String, dynamic>)['payments'] as List)
              .map((p) => PaymentModel.fromJson(p as Map<String, dynamic>))
              .toList(),
    );
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
  }) {
    return cacheable(
      cache: _cache,
      key: 'transactions:$flatId:p$page:l$limit:'
          '${memberId ?? ''}:${type ?? ''}:${category ?? ''}:${from ?? ''}:${to ?? ''}',
      fetchRaw: () => getTransactionsRaw(
        flatId,
        memberId: memberId,
        type: type,
        category: category,
        from: from,
        to: to,
        page: page,
        limit: limit,
      ),
      parse: (data) => (data['transactions'] as List)
          .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<PaymentHintsModel> getPaymentHints(String flatId) => cacheable(
        cache: _cache,
        key: 'payment_hints:$flatId',
        fetchRaw: () =>
            _apiClient.get(ApiEndpoints.flatPaymentHints(flatId), auth: true),
        parse: (json) => PaymentHintsModel.fromJson(
            (json['data'] as Map<String, dynamic>)['hints']
                as Map<String, dynamic>),
      );

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
