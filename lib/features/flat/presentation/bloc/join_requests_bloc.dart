import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/join_request_entity.dart';
import '../../domain/usecases/approve_join_request_usecase.dart';
import '../../domain/usecases/decline_join_request_usecase.dart';
import '../../domain/usecases/get_join_requests_usecase.dart';
import 'join_requests_event.dart';
import 'join_requests_state.dart';

export 'join_requests_event.dart';
export 'join_requests_state.dart';

class JoinRequestsBloc extends Bloc<JoinRequestsEvent, JoinRequestsState> {
  final GetJoinRequestsUseCase _getJoinRequests;
  final ApproveJoinRequestUseCase _approve;
  final DeclineJoinRequestUseCase _decline;

  JoinRequestsBloc({
    required GetJoinRequestsUseCase getJoinRequests,
    required ApproveJoinRequestUseCase approve,
    required DeclineJoinRequestUseCase decline,
  })  : _getJoinRequests = getJoinRequests,
        _approve = approve,
        _decline = decline,
        super(const JoinRequestsInitial()) {
    on<JoinRequestsLoadRequested>(_onLoad);
    on<JoinRequestApproveRequested>(_onApprove);
    on<JoinRequestDeclineRequested>(_onDecline);
  }

  Future<void> _onLoad(
    JoinRequestsLoadRequested event,
    Emitter<JoinRequestsState> emit,
  ) async {
    emit(const JoinRequestsLoading());
    try {
      final requests = await _getJoinRequests(event.flatId);
      emit(JoinRequestsLoaded(requests));
    } catch (e) {
      emit(JoinRequestsLoadError(_message(e)));
    }
  }

  Future<void> _onApprove(
    JoinRequestApproveRequested event,
    Emitter<JoinRequestsState> emit,
  ) async {
    final current = _currentRequests;
    if (current == null) return;
    emit(JoinRequestsActionInProgress(
      requests: current,
      requestId: event.requestId,
    ));
    try {
      await _approve(
        flatId: event.flatId,
        requestId: event.requestId,
        fixedContribution: event.fixedContribution,
      );
      final updated = await _getJoinRequests(event.flatId);
      emit(JoinRequestsLoaded(updated));
    } catch (e) {
      emit(JoinRequestsActionError(requests: current, message: _message(e)));
    }
  }

  Future<void> _onDecline(
    JoinRequestDeclineRequested event,
    Emitter<JoinRequestsState> emit,
  ) async {
    final current = _currentRequests;
    if (current == null) return;
    emit(JoinRequestsActionInProgress(
      requests: current,
      requestId: event.requestId,
    ));
    try {
      await _decline(flatId: event.flatId, requestId: event.requestId);
      final updated = await _getJoinRequests(event.flatId);
      emit(JoinRequestsLoaded(updated));
    } catch (e) {
      emit(JoinRequestsActionError(requests: current, message: _message(e)));
    }
  }

  List<JoinRequestEntity>? get _currentRequests {
    final s = state;
    if (s is JoinRequestsLoaded) return s.requests;
    if (s is JoinRequestsActionInProgress) return s.requests;
    if (s is JoinRequestsActionError) return s.requests;
    return null;
  }

  String _message(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
