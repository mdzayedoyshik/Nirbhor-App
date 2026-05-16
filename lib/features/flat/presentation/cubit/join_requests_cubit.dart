import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/join_request_entity.dart';
import '../../domain/usecases/approve_join_request_usecase.dart';
import '../../domain/usecases/decline_join_request_usecase.dart';
import '../../domain/usecases/get_join_requests_usecase.dart';

part 'join_requests_state.dart';

class JoinRequestsCubit extends Cubit<JoinRequestsState> {
  final GetJoinRequestsUseCase _getJoinRequests;
  final ApproveJoinRequestUseCase _approve;
  final DeclineJoinRequestUseCase _decline;

  JoinRequestsCubit({
    required GetJoinRequestsUseCase getJoinRequests,
    required ApproveJoinRequestUseCase approve,
    required DeclineJoinRequestUseCase decline,
  }) : _getJoinRequests = getJoinRequests,
       _approve = approve,
       _decline = decline,
       super(const JoinRequestsInitial());

  Future<void> load(String flatId) async {
    emit(const JoinRequestsLoading());
    try {
      final requests = await _getJoinRequests(flatId);
      emit(JoinRequestsLoaded(requests));
    } catch (e) {
      emit(JoinRequestsError(_message(e)));
    }
  }

  Future<void> approve({
    required String flatId,
    required String requestId,
    required double fixedContribution,
  }) async {
    final current = state;
    emit(JoinRequestsActionLoading(requestId));
    try {
      await _approve(
        flatId: flatId,
        requestId: requestId,
        fixedContribution: fixedContribution,
      );
      // Reload after approve
      await load(flatId);
    } catch (e) {
      if (current is JoinRequestsLoaded) {
        emit(current);
      }
      emit(JoinRequestsActionError(requestId, _message(e)));
    }
  }

  Future<void> decline({
    required String flatId,
    required String requestId,
  }) async {
    final current = state;
    emit(JoinRequestsActionLoading(requestId));
    try {
      await _decline(flatId: flatId, requestId: requestId);
      await load(flatId);
    } catch (e) {
      if (current is JoinRequestsLoaded) {
        emit(current);
      }
      emit(JoinRequestsActionError(requestId, _message(e)));
    }
  }

  String _message(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
