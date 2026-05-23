import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../flat/domain/entities/flat_member_entity.dart';
import '../../domain/usecases/change_role_usecase.dart';
import '../../domain/usecases/get_members_usecase.dart';
import '../../domain/usecases/get_settlement_usecase.dart';
import '../../domain/usecases/initiate_exit_usecase.dart';
import '../../domain/usecases/transfer_manager_usecase.dart';
import 'member_event.dart';
import 'member_state.dart';

export 'member_event.dart';
export 'member_state.dart';

class MemberBloc extends Bloc<MemberEvent, MemberState> {
  final GetMembersUseCase _getMembers;
  final ChangeRoleUseCase _changeRole;
  final TransferManagerUseCase _transferManager;
  final InitiateExitUseCase _initiateExit;
  final GetSettlementUseCase _getSettlement;

  MemberBloc({
    required GetMembersUseCase getMembers,
    required ChangeRoleUseCase changeRole,
    required TransferManagerUseCase transferManager,
    required InitiateExitUseCase initiateExit,
    required GetSettlementUseCase getSettlement,
  })  : _getMembers = getMembers,
        _changeRole = changeRole,
        _transferManager = transferManager,
        _initiateExit = initiateExit,
        _getSettlement = getSettlement,
        super(const MemberInitial()) {
    on<MemberLoadRequested>(_onLoad);
    on<MemberRoleChangeRequested>(_onChangeRole);
    on<ManagerTransferRequested>(_onTransferManager);
    on<MemberExitInitiateRequested>(_onInitiateExit);
    on<MemberSettlementViewRequested>(_onViewSettlement);
    on<MemberSettlementAcknowledged>(_onAcknowledgeSettlement);
  }

  List<FlatMemberEntity>? _cachedMembers;

  Future<void> _onLoad(
    MemberLoadRequested event,
    Emitter<MemberState> emit,
  ) async {
    if (_cachedMembers != null) {
      emit(MemberLoaded(members: _cachedMembers!));
      try {
        final fresh = await _getMembers(event.flatId);
        _cachedMembers = fresh;
        emit(MemberLoaded(members: fresh));
      } catch (_) {}
    } else {
      emit(const MemberLoading());
      try {
        final members = await _getMembers(event.flatId);
        _cachedMembers = members;
        emit(MemberLoaded(members: members));
      } catch (e) {
        emit(MemberLoadError(_msg(e)));
      }
    }
  }

  Future<void> _onChangeRole(
    MemberRoleChangeRequested event,
    Emitter<MemberState> emit,
  ) async {
    final (members, exitIds) = _currentData;
    if (members == null || exitIds == null) return;
    emit(MemberActionLoading(members: members, exitInProgressIds: exitIds));
    try {
      await _changeRole(
        flatId: event.flatId,
        memberId: event.memberId,
        role: event.role,
      );
      final updated = await _getMembers(event.flatId);
      _cachedMembers = updated;
      emit(MemberLoaded(members: updated, exitInProgressIds: exitIds));
    } catch (e) {
      emit(MemberLoaded(members: members, exitInProgressIds: exitIds));
      emit(MemberActionError(
        message: _msg(e),
        members: members,
        exitInProgressIds: exitIds,
      ));
    }
  }

  Future<void> _onTransferManager(
    ManagerTransferRequested event,
    Emitter<MemberState> emit,
  ) async {
    final (members, exitIds) = _currentData;
    if (members == null || exitIds == null) return;
    emit(MemberActionLoading(members: members, exitInProgressIds: exitIds));
    try {
      await _transferManager(
        flatId: event.flatId,
        newManagerId: event.newManagerId,
      );
      final updated = await _getMembers(event.flatId);
      _cachedMembers = updated;
      emit(MemberLoaded(members: updated, exitInProgressIds: exitIds));
    } catch (e) {
      emit(MemberLoaded(members: members, exitInProgressIds: exitIds));
      emit(MemberActionError(
        message: _msg(e),
        members: members,
        exitInProgressIds: exitIds,
      ));
    }
  }

  Future<void> _onInitiateExit(
    MemberExitInitiateRequested event,
    Emitter<MemberState> emit,
  ) async {
    final (members, exitIds) = _currentData;
    if (members == null || exitIds == null) return;
    emit(MemberActionLoading(members: members, exitInProgressIds: exitIds));
    try {
      final settlement = await _initiateExit(
        flatId: event.flatId,
        memberId: event.memberId,
        fixedRefund: event.fixedRefund,
      );
      final newExitIds = {...exitIds, event.memberId};
      emit(MemberSettlementReady(
        members: members,
        exitInProgressIds: newExitIds,
        settlement: settlement,
        memberId: event.memberId,
      ));
    } catch (e) {
      // 409 = exit already in progress — load the existing settlement instead
      if (e is ServerException && e.statusCode == 409) {
        try {
          final settlement = await _getSettlement(
            flatId: event.flatId,
            memberId: event.memberId,
          );
          final newExitIds = {...exitIds, event.memberId};
          emit(MemberSettlementReady(
            members: members,
            exitInProgressIds: newExitIds,
            settlement: settlement,
            memberId: event.memberId,
          ));
          return;
        } catch (_) {
          // fall through to generic error
        }
      }
      emit(MemberLoaded(members: members, exitInProgressIds: exitIds));
      emit(MemberActionError(
        message: _msg(e),
        members: members,
        exitInProgressIds: exitIds,
      ));
    }
  }

  Future<void> _onViewSettlement(
    MemberSettlementViewRequested event,
    Emitter<MemberState> emit,
  ) async {
    final (members, exitIds) = _currentData;
    if (members == null || exitIds == null) return;
    emit(MemberActionLoading(members: members, exitInProgressIds: exitIds));
    try {
      final settlement = await _getSettlement(
        flatId: event.flatId,
        memberId: event.memberId,
      );
      final newExitIds = {...exitIds, event.memberId};
      emit(MemberSettlementReady(
        members: members,
        exitInProgressIds: newExitIds,
        settlement: settlement,
        memberId: event.memberId,
      ));
    } catch (e) {
      emit(MemberLoaded(members: members, exitInProgressIds: exitIds));
      emit(MemberActionError(
        message: _msg(e),
        members: members,
        exitInProgressIds: exitIds,
      ));
    }
  }

  void _onAcknowledgeSettlement(
    MemberSettlementAcknowledged event,
    Emitter<MemberState> emit,
  ) {
    final s = state;
    if (s is MemberSettlementReady) {
      emit(MemberLoaded(
        members: s.members,
        exitInProgressIds: s.exitInProgressIds,
      ));
    }
  }

  (List<FlatMemberEntity>?, Set<String>?) get _currentData {
    final s = state;
    if (s is MemberLoaded) return (s.members, s.exitInProgressIds);
    if (s is MemberActionLoading) return (s.members, s.exitInProgressIds);
    if (s is MemberSettlementReady) return (s.members, s.exitInProgressIds);
    if (s is MemberActionError) return (s.members, s.exitInProgressIds);
    return (null, null);
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
