import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/exceptions.dart';
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
  })  : _getWalletSummary = getWalletSummary,
        _getFlatWallet = getFlatWallet,
        _submitPayment = submitPayment,
        super(const WalletInitial()) {
    on<WalletSummaryRequested>(_onSummaryRequested);
    on<WalletPaymentSubmitRequested>(_onPaymentSubmit);
  }

  final GetWalletSummaryUseCase _getWalletSummary;
  final GetFlatWalletUseCase _getFlatWallet;
  final SubmitPaymentUseCase _submitPayment;

  Future<(WalletSummaryEntity, FlatWalletEntity?)> _fetchBoth(
      String flatId) async {
    final summaryFuture = _getWalletSummary(flatId);
    final flatWalletFuture = _getFlatWallet(flatId)
        .then<FlatWalletEntity?>((v) => v)
        .onError((_, __) => null);
    return (await summaryFuture, await flatWalletFuture);
  }

  Future<void> _onSummaryRequested(
    WalletSummaryRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    try {
      final (summary, flatWallet) = await _fetchBoth(event.flatId);
      emit(WalletSummaryLoaded(summary, flatWallet: flatWallet));
    } catch (e) {
      emit(WalletError(_msg(e)));
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
      emit(WalletPaymentSubmitSuccess(refreshed, flatWallet: refreshedFlat));
    } catch (e) {
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
