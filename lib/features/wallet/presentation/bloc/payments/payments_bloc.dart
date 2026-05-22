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

  Future<void> _onLoad(
    PaymentsLoadRequested event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(const PaymentsLoading());
    try {
      final payments =
          await _getPayments(event.flatId, status: event.status);
      emit(PaymentsLoaded(payments, statusFilter: event.status));
    } catch (e) {
      emit(PaymentsError(_msg(e)));
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
      final result =
          await _verifyPayment(event.flatId, event.paymentId);
      final refreshed =
          await _getPayments(event.flatId, status: _currentStatus);
      emit(PaymentVerifySuccess(result: result, payments: refreshed));
    } catch (e) {
      emit(PaymentsLoaded(current, statusFilter: _currentStatus));
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
      await _rejectPayment(event.flatId, event.paymentId,
          reason: event.reason);
      final refreshed =
          await _getPayments(event.flatId, status: _currentStatus);
      emit(PaymentRejectSuccess(refreshed));
    } catch (e) {
      emit(PaymentsLoaded(current, statusFilter: _currentStatus));
      emit(PaymentsActionError(message: _msg(e), payments: current));
    }
  }

  void _onAcknowledge(
    PaymentVerifyResultAcknowledged event,
    Emitter<PaymentsState> emit,
  ) {
    final s = state;
    if (s is PaymentVerifySuccess) {
      emit(PaymentsLoaded(s.payments, statusFilter: _currentStatus));
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

  String? get _currentStatus {
    final s = state;
    if (s is PaymentsLoaded) return s.statusFilter;
    return null;
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
