import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../member/domain/entities/settlement_entity.dart';
import '../../../member/domain/usecases/get_exit_status_usecase.dart';
import '../../domain/entities/flat_entity.dart';
import '../../domain/entities/join_request_entity.dart';
import '../../domain/usecases/cancel_join_request_usecase.dart';
import '../../domain/usecases/create_flat_usecase.dart';
import '../../domain/usecases/delete_flat_usecase.dart';
import '../../domain/usecases/get_my_flat_usecase.dart';
import '../../domain/usecases/get_my_requests_usecase.dart';
import '../../domain/usecases/send_join_request_usecase.dart';
import '../../domain/usecases/update_flat_usecase.dart';

part 'flat_event.dart';
part 'flat_state.dart';

class FlatBloc extends Bloc<FlatEvent, FlatState> {
  final GetMyFlatUseCase _getMyFlat;
  final CreateFlatUseCase _createFlat;
  final UpdateFlatUseCase _updateFlat;
  final DeleteFlatUseCase _deleteFlat;
  final SendJoinRequestUseCase _sendJoinRequest;
  final GetMyRequestsUseCase _getMyRequests;
  final CancelJoinRequestUseCase _cancelJoinRequest;
  final GetExitStatusUseCase _getExitStatus;

  FlatBloc({
    required GetMyFlatUseCase getMyFlat,
    required CreateFlatUseCase createFlat,
    required UpdateFlatUseCase updateFlat,
    required DeleteFlatUseCase deleteFlat,
    required SendJoinRequestUseCase sendJoinRequest,
    required GetMyRequestsUseCase getMyRequests,
    required CancelJoinRequestUseCase cancelJoinRequest,
    required GetExitStatusUseCase getExitStatus,
  }) : _getMyFlat = getMyFlat,
       _createFlat = createFlat,
       _updateFlat = updateFlat,
       _deleteFlat = deleteFlat,
       _sendJoinRequest = sendJoinRequest,
       _getMyRequests = getMyRequests,
       _cancelJoinRequest = cancelJoinRequest,
       _getExitStatus = getExitStatus,
       super(const FlatInitial()) {
    on<FlatCheckRequested>(_onCheck);
    on<FlatRefreshRequested>(_onRefresh);
    on<FlatCreateRequested>(_onCreate);
    on<FlatUpdateRequested>(_onUpdate);
    on<FlatDeleteRequested>(_onDelete);
    on<FlatJoinRequested>(_onJoin);
    on<FlatCancelRequestRequested>(_onCancelRequest);
  }

  Future<void> _onCheck(
    FlatCheckRequested event,
    Emitter<FlatState> emit,
  ) async {
    emit(const FlatChecking());
    try {
      final flat = await _getMyFlat();
      // Member has an active flat — check for pending exit
      try {
        final exitStatus = await _getExitStatus();
        if (exitStatus.isPending && exitStatus.settlement != null) {
          emit(FlatPendingExit(flat, exitStatus.settlement!));
          return;
        }
      } catch (_) {
        // If exit status check fails, fall through to FlatLoaded
      }
      emit(FlatLoaded(flat));
    } on ServerException catch (e) {
      if (e.statusCode == 404) {
        // No active flat — check for awaiting acknowledgment first
        try {
          final exitStatus = await _getExitStatus();
          if (exitStatus.isAwaitingAck &&
              exitStatus.settlement != null &&
              exitStatus.flatName != null) {
            emit(FlatExitPendingAck(
              settlement: exitStatus.settlement!,
              flatName: exitStatus.flatName!,
            ));
            return;
          }
        } catch (_) {
          // If exit status check fails, fall through to pending request check
        }
        // No exit pending ack — check for pending join requests
        try {
          final requests = await _getMyRequests();
          final pending = requests.where((r) => r.isPending).toList();
          if (pending.isNotEmpty) {
            emit(FlatPendingRequest(pending.first));
          } else {
            emit(const FlatNone());
          }
        } catch (_) {
          emit(const FlatNone());
        }
      } else {
        emit(FlatError(e.message, const FlatNone()));
      }
    } catch (_) {
      emit(const FlatError('Failed to load flat data.', FlatNone()));
    }
  }

  Future<void> _onRefresh(
    FlatRefreshRequested event,
    Emitter<FlatState> emit,
  ) async {
    final base = state is FlatLoaded ? state : const FlatNone();
    emit(FlatActionLoading(FlatLoadingSource.refresh, base));
    try {
      final flat = await _getMyFlat();
      // Also refresh fixed expenses to get latest contributions
      emit(FlatLoaded(flat));
    } catch (e) {
      emit(FlatError(_message(e), base));
    }
  }

  Future<void> _onCreate(
    FlatCreateRequested event,
    Emitter<FlatState> emit,
  ) async {
    emit(const FlatActionLoading(FlatLoadingSource.create, FlatNone()));
    try {
      final flat = await _createFlat(
        name: event.name,
        address: event.address,
        photoUrl: event.photoUrl,
      );
      emit(FlatLoaded(flat));
    } catch (e) {
      emit(FlatError(_message(e), const FlatNone()));
    }
  }

  Future<void> _onUpdate(
    FlatUpdateRequested event,
    Emitter<FlatState> emit,
  ) async {
    final base = state;
    emit(FlatActionLoading(FlatLoadingSource.update, base));
    try {
      final flat = await _updateFlat(
        flatId: event.flatId,
        name: event.name,
        address: event.address,
        photoUrl: event.photoUrl,
      );
      emit(FlatLoaded(flat));
    } catch (e) {
      emit(FlatError(_message(e), base));
    }
  }

  Future<void> _onDelete(
    FlatDeleteRequested event,
    Emitter<FlatState> emit,
  ) async {
    final base = state;
    emit(FlatActionLoading(FlatLoadingSource.delete, base));
    try {
      await _deleteFlat(event.flatId);
      emit(const FlatNone());
    } catch (e) {
      emit(FlatError(_message(e), base));
    }
  }

  Future<void> _onJoin(FlatJoinRequested event, Emitter<FlatState> emit) async {
    emit(const FlatActionLoading(FlatLoadingSource.join, FlatNone()));
    try {
      final request = await _sendJoinRequest(event.joinCode);
      emit(FlatPendingRequest(request));
    } catch (e) {
      emit(FlatError(_message(e), const FlatNone()));
    }
  }

  Future<void> _onCancelRequest(
    FlatCancelRequestRequested event,
    Emitter<FlatState> emit,
  ) async {
    final base = state;
    emit(FlatActionLoading(FlatLoadingSource.cancelRequest, base));
    try {
      await _cancelJoinRequest(event.requestId);
      emit(const FlatNone());
    } catch (e) {
      emit(FlatError(_message(e), base));
    }
  }

  String _message(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
