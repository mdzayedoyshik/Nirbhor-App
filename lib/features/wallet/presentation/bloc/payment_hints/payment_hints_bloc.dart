import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/exceptions.dart';
import '../../../domain/usecases/get_payment_hints_usecase.dart';
import '../../../domain/usecases/update_payment_hints_usecase.dart';
import 'payment_hints_event.dart';
import 'payment_hints_state.dart';

export 'payment_hints_event.dart';
export 'payment_hints_state.dart';

class PaymentHintsBloc extends Bloc<PaymentHintsEvent, PaymentHintsState> {
  PaymentHintsBloc({
    required GetPaymentHintsUseCase getPaymentHints,
    required UpdatePaymentHintsUseCase updatePaymentHints,
  })  : _getPaymentHints = getPaymentHints,
        _updatePaymentHints = updatePaymentHints,
        super(const PaymentHintsInitial()) {
    on<PaymentHintsLoadRequested>(_onLoad);
    on<PaymentHintsUpdateRequested>(_onUpdate);
  }

  final GetPaymentHintsUseCase _getPaymentHints;
  final UpdatePaymentHintsUseCase _updatePaymentHints;

  Future<void> _onLoad(
    PaymentHintsLoadRequested event,
    Emitter<PaymentHintsState> emit,
  ) async {
    emit(const PaymentHintsLoading());
    try {
      final hints = await _getPaymentHints(event.flatId);
      emit(PaymentHintsLoaded(hints));
    } catch (e) {
      emit(PaymentHintsError(_msg(e)));
    }
  }

  Future<void> _onUpdate(
    PaymentHintsUpdateRequested event,
    Emitter<PaymentHintsState> emit,
  ) async {
    final current = state;
    final hints = current is PaymentHintsLoaded ? current.hints : null;
    if (hints != null) emit(PaymentHintsActionLoading(hints));
    try {
      final updated = await _updatePaymentHints(
        event.flatId,
        suggestedMealAmount: event.suggestedMealAmount,
        suggestedHouseholdAmount: event.suggestedHouseholdAmount,
      );
      emit(PaymentHintsUpdateSuccess(updated));
    } catch (e) {
      if (hints != null) emit(PaymentHintsLoaded(hints));
      emit(PaymentHintsError(_msg(e), hints: hints));
    }
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
