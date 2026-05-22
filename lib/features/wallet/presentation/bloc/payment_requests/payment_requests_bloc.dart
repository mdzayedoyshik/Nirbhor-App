import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/exceptions.dart';
import '../../../domain/entities/payment_request_entity.dart';
import '../../../domain/usecases/cancel_payment_request_usecase.dart';
import '../../../domain/usecases/create_payment_request_usecase.dart';
import '../../../domain/usecases/get_payment_requests_usecase.dart';
import 'payment_requests_event.dart';
import 'payment_requests_state.dart';

export 'payment_requests_event.dart';
export 'payment_requests_state.dart';

class PaymentRequestsBloc
    extends Bloc<PaymentRequestsEvent, PaymentRequestsState> {
  PaymentRequestsBloc({
    required GetPaymentRequestsUseCase getPaymentRequests,
    required CreatePaymentRequestUseCase createPaymentRequest,
    required CancelPaymentRequestUseCase cancelPaymentRequest,
  })  : _getPaymentRequests = getPaymentRequests,
        _createPaymentRequest = createPaymentRequest,
        _cancelPaymentRequest = cancelPaymentRequest,
        super(const PaymentRequestsInitial()) {
    on<PaymentRequestsLoadRequested>(_onLoad);
    on<PaymentRequestCreateRequested>(_onCreate);
    on<PaymentRequestBulkCreateRequested>(_onBulkCreate);
    on<PaymentRequestCancelRequested>(_onCancel);
  }

  final GetPaymentRequestsUseCase _getPaymentRequests;
  final CreatePaymentRequestUseCase _createPaymentRequest;
  final CancelPaymentRequestUseCase _cancelPaymentRequest;

  Future<void> _onLoad(
    PaymentRequestsLoadRequested event,
    Emitter<PaymentRequestsState> emit,
  ) async {
    emit(const PaymentRequestsLoading());
    try {
      final requests =
          await _getPaymentRequests(event.flatId, status: event.status);
      emit(PaymentRequestsLoaded(requests, statusFilter: event.status));
    } catch (e) {
      emit(PaymentRequestsError(_msg(e)));
    }
  }

  Future<void> _onCreate(
    PaymentRequestCreateRequested event,
    Emitter<PaymentRequestsState> emit,
  ) async {
    final current = _currentRequests;
    if (current != null) emit(PaymentRequestsActionLoading(current));
    try {
      await _createPaymentRequest(
        flatId: event.flatId,
        requestedTo: event.requestedTo,
        amount: event.amount,
        note: event.note,
      );
      final refreshed =
          await _getPaymentRequests(event.flatId, status: _currentStatus);
      emit(PaymentRequestCreateSuccess(refreshed));
    } catch (e) {
      final fallback = current ?? <PaymentRequestEntity>[];
      if (current != null) emit(PaymentRequestsLoaded(current));
      emit(PaymentRequestsActionError(message: _msg(e), requests: fallback));
    }
  }

  Future<void> _onBulkCreate(
    PaymentRequestBulkCreateRequested event,
    Emitter<PaymentRequestsState> emit,
  ) async {
    final current = _currentRequests;
    if (current != null) emit(PaymentRequestsActionLoading(current));
    int sentCount = 0;
    int skippedCount = 0;
    String? lastError;
    for (final memberId in event.memberIds) {
      try {
        await _createPaymentRequest(
          flatId: event.flatId,
          requestedTo: memberId,
          amount: event.amount,
          note: event.note,
        );
        sentCount++;
      } catch (e) {
        skippedCount++;
        lastError = _msg(e);
      }
    }
    final refreshed =
        await _getPaymentRequests(event.flatId, status: _currentStatus);
    if (sentCount == 0 && lastError != null) {
      emit(PaymentRequestsLoaded(refreshed, statusFilter: _currentStatus));
      emit(PaymentRequestsActionError(
          message: lastError, requests: refreshed));
    } else {
      emit(PaymentRequestBulkCreateSuccess(refreshed,
          sentCount: sentCount, skippedCount: skippedCount));
      emit(PaymentRequestsLoaded(refreshed, statusFilter: _currentStatus));
    }
  }

  Future<void> _onCancel(
    PaymentRequestCancelRequested event,
    Emitter<PaymentRequestsState> emit,
  ) async {
    final current = _currentRequests;
    if (current != null) emit(PaymentRequestsActionLoading(current));
    try {
      await _cancelPaymentRequest(event.flatId, event.requestId);
      final refreshed =
          await _getPaymentRequests(event.flatId, status: _currentStatus);
      emit(PaymentRequestCancelSuccess(refreshed));
    } catch (e) {
      final fallback = current ?? <PaymentRequestEntity>[];
      if (current != null) emit(PaymentRequestsLoaded(current));
      emit(PaymentRequestsActionError(message: _msg(e), requests: fallback));
    }
  }

  List<PaymentRequestEntity>? get _currentRequests {
    final s = state;
    if (s is PaymentRequestsLoaded) return s.requests;
    if (s is PaymentRequestsActionLoading) return s.requests;
    if (s is PaymentRequestCreateSuccess) return s.requests;
    if (s is PaymentRequestCancelSuccess) return s.requests;
    if (s is PaymentRequestsActionError) return s.requests;
    return null;
  }

  String? get _currentStatus {
    final s = state;
    if (s is PaymentRequestsLoaded) return s.statusFilter;
    return null;
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
