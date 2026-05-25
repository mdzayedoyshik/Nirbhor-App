import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/exceptions.dart';
import '../../../domain/entities/payment_entity.dart';
import '../../../domain/usecases/get_payments_usecase.dart';
import '../../../domain/usecases/reject_payment_usecase.dart';
import '../../../domain/usecases/verify_payment_usecase.dart';
import 'payments_event.dart';
import 'payments_state.dart';

export 'payments_event.dart';
export 'payments_state.dart';

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  PaymentsBloc({
    required GetPaymentsUseCase getPayments,
    required VerifyPaymentUseCase verifyPayment,
    required RejectPaymentUseCase rejectPayment,
  })  : _getPayments = getPayments,
        _verifyPayment = verifyPayment,
        _rejectPayment = rejectPayment,
        super(const PaymentsInitial()) {
    on<PaymentsLoadRequested>(_onLoad);
    on<PaymentVerifyRequested>(_onVerify);
    on<PaymentRejectRequested>(_onReject);
    on<PaymentVerifyResultAcknowledged>(_onAcknowledge);
  }

  final GetPaymentsUseCase _getPayments;
  final VerifyPaymentUseCase _verifyPayment;
  final RejectPaymentUseCase _rejectPayment;

  // Cache per status tab — avoids loading spinner on tab switch
  final Map<String?, List<PaymentEntity>> _cache = {};
  // Always tracks the active tab status regardless of state type
  String? _activeStatus;

  Future<void> _onLoad(
    PaymentsLoadRequested event,
    Emitter<PaymentsState> emit,
  ) async {
    _activeStatus = event.status;
    final cached = _cache[event.status];
    if (cached != null) {
      // Show stale data immediately, then refresh silently in background
      emit(PaymentsLoaded(cached, statusFilter: event.status));
      try {
        final fresh = await _getPayments(event.flatId, status: event.status);
        _cache[event.status] = fresh;
        if (_activeStatus == event.status) {
          emit(PaymentsLoaded(fresh, statusFilter: event.status));
        }
      } catch (_) {
        // Keep showing cached data — no error flash on background refresh
      }
    } else {
      emit(const PaymentsLoading());
      try {
        final payments = await _getPayments(event.flatId, status: event.status);
        _cache[event.status] = payments;
        emit(PaymentsLoaded(payments, statusFilter: event.status));
      } catch (e) {
        emit(PaymentsError(_msg(e)));
      }
    }
  }

  Future<void> _onVerify(
    PaymentVerifyRequested event,
    Emitter<PaymentsState> emit,
  ) async {
    final current = _currentPayments;
    if (current == null) return;
    emit(PaymentsActionLoading(current));
    try {
      final result = await _verifyPayment(event.flatId, event.paymentId);
      // Invalidate both pending and verified cache since an item moved between them
      _cache.remove('pending');
      _cache.remove('verified');
      final refreshed = await _getPayments(event.flatId, status: _activeStatus);
      _cache[_activeStatus] = refreshed;
      emit(PaymentVerifySuccess(result: result, payments: refreshed));
    } catch (e) {
      emit(PaymentsLoaded(current, statusFilter: _activeStatus));
      emit(PaymentsActionError(message: _msg(e), payments: current));
    }
  }

  Future<void> _onReject(
    PaymentRejectRequested event,
    Emitter<PaymentsState> emit,
  ) async {
    final current = _currentPayments;
    if (current == null) return;
    emit(PaymentsActionLoading(current));
    try {
      await _rejectPayment(event.flatId, event.paymentId, reason: event.reason);
      _cache.remove('pending');
      _cache.remove('rejected');
      final refreshed = await _getPayments(event.flatId, status: _activeStatus);
      _cache[_activeStatus] = refreshed;
      emit(PaymentRejectSuccess(refreshed));
    } catch (e) {
      emit(PaymentsLoaded(current, statusFilter: _activeStatus));
      emit(PaymentsActionError(message: _msg(e), payments: current));
    }
  }

  void _onAcknowledge(
    PaymentVerifyResultAcknowledged event,
    Emitter<PaymentsState> emit,
  ) {
    final s = state;
    if (s is PaymentVerifySuccess) {
      emit(PaymentsLoaded(s.payments, statusFilter: _activeStatus));
    }
  }

  List<PaymentEntity>? get _currentPayments {
    final s = state;
    if (s is PaymentsLoaded) return s.payments;
    if (s is PaymentsActionLoading) return s.payments;
    if (s is PaymentVerifySuccess) return s.payments;
    if (s is PaymentRejectSuccess) return s.payments;
    if (s is PaymentsActionError) return s.payments;
    return null;
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
