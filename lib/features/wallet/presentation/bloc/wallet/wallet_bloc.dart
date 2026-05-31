import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/services/analytics_service.dart';
import '../../../domain/entities/flat_wallet_entity.dart';
import '../../../domain/entities/wallet_summary_entity.dart';
import '../../../domain/usecases/get_flat_wallet_usecase.dart';
import '../../../domain/usecases/get_wallet_summary_usecase.dart';
import '../../../domain/usecases/submit_payment_usecase.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

export 'wallet_event.dart';
export 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc({
    required GetWalletSummaryUseCase getWalletSummary,
    required GetFlatWalletUseCase getFlatWallet,
    required SubmitPaymentUseCase submitPayment,
    required AnalyticsService analytics,
  })  : _getWalletSummary = getWalletSummary,
        _getFlatWallet = getFlatWallet,
        _submitPayment = submitPayment,
        _analytics = analytics,
        super(const WalletInitial()) {
    on<WalletSummaryRequested>(_onSummaryRequested);
    on<WalletPaymentSubmitRequested>(_onPaymentSubmit);
  }

  final GetWalletSummaryUseCase _getWalletSummary;
  final GetFlatWalletUseCase _getFlatWallet;
  final SubmitPaymentUseCase _submitPayment;
  final AnalyticsService _analytics;

  WalletSummaryEntity? _cachedSummary;
  FlatWalletEntity? _cachedFlatWallet;

  Future<(WalletSummaryEntity, FlatWalletEntity?)> _fetchBoth(
      String flatId) async {
    final summaryFuture = _getWalletSummary(flatId);
    final flatWalletFuture = _getFlatWallet(flatId)
        .then<FlatWalletEntity?>((v) => v)
        .onError((e, st) => null);
    return (await summaryFuture, await flatWalletFuture);
  }

  Future<void> _onSummaryRequested(
    WalletSummaryRequested event,
    Emitter<WalletState> emit,
  ) async {
    if (_cachedSummary != null) {
      // Show cached data immediately, refresh silently in background
      emit(WalletSummaryLoaded(_cachedSummary!, flatWallet: _cachedFlatWallet));
      try {
        final (summary, flatWallet) = await _fetchBoth(event.flatId);
        _cachedSummary = summary;
        _cachedFlatWallet = flatWallet;
        emit(WalletSummaryLoaded(summary, flatWallet: flatWallet));
        try {
          await _analytics.logWalletViewed(flatId: event.flatId);
          await _analytics.logWalletBalanceChecked(flatId: event.flatId);
        } catch (_) {}
      } catch (_) {
        // Keep showing cached data silently
      }
    } else {
      // _cachedSummary == null means this is the very first wallet load this
      // session (WalletBloc is a singleton). Use it as the "first wallet setup"
      // milestone in the onboarding funnel.
      emit(const WalletLoading());
      try {
        final (summary, flatWallet) = await _fetchBoth(event.flatId);
        _cachedSummary = summary;
        _cachedFlatWallet = flatWallet;
        emit(WalletSummaryLoaded(summary, flatWallet: flatWallet));
        try {
          await _analytics.logWalletViewed(flatId: event.flatId);
          await _analytics.logWalletBalanceChecked(flatId: event.flatId);
          await _analytics.logFirstWalletSetup(
            flatId: event.flatId,
            walletType: 'shared',
          );
        } catch (_) {}
      } catch (e, stackTrace) {
        _analytics.recordException(e, stackTrace, reason: 'WalletBloc._onSummaryRequested');
        emit(WalletError(_msg(e)));
      }
    }
  }

  Future<void> _onPaymentSubmit(
    WalletPaymentSubmitRequested event,
    Emitter<WalletState> emit,
  ) async {
    final current = state;
    final summary =
        current is WalletSummaryLoaded ? current.summary : null;
    final flatWallet =
        current is WalletSummaryLoaded ? current.flatWallet : null;
    if (summary != null) {
      emit(WalletActionLoading(summary, flatWallet: flatWallet));
    }
    try {
      await _submitPayment(
        flatId: event.flatId,
        amount: event.amount,
        paymentMethod: event.paymentMethod,
        paymentRequestId: event.paymentRequestId,
        note: event.note,
      );
      final (refreshed, refreshedFlat) = await _fetchBoth(event.flatId);
      _cachedSummary = refreshed;
      _cachedFlatWallet = refreshedFlat;
      emit(WalletPaymentSubmitSuccess(refreshed, flatWallet: refreshedFlat));
      try {
        await _analytics.logWalletTransactionAdded(
          flatId: event.flatId,
          transactionType: 'payment',
          amount: event.amount,
          paymentMethod: event.paymentMethod,
        );
      } catch (_) {}
    } catch (e, stackTrace) {
      _analytics.recordException(e, stackTrace, reason: 'WalletBloc._onPaymentSubmit');
      if (summary != null) {
        emit(WalletSummaryLoaded(summary, flatWallet: flatWallet));
      }
      emit(WalletError(_msg(e), summary: summary, flatWallet: flatWallet));
    }
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
