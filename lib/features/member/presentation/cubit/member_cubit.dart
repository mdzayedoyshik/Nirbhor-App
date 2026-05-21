import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../flat/domain/entities/flat_member_entity.dart';
import '../../domain/entities/finalize_exit_entity.dart';
import '../../domain/entities/settlement_entity.dart';
import '../../domain/usecases/cancel_exit_usecase.dart';
import '../../domain/usecases/change_role_usecase.dart';
import '../../domain/usecases/finalize_exit_usecase.dart';
import '../../domain/usecases/get_members_usecase.dart';
import '../../domain/usecases/get_settlement_usecase.dart';
import '../../domain/usecases/initiate_exit_usecase.dart';
import '../../domain/usecases/transfer_manager_usecase.dart';

// ─── States ──────────────────────────────────────────────────────────────────

abstract class MemberState extends Equatable {
  const MemberState();
}

class MemberInitial extends MemberState {
  const MemberInitial();
  @override
  List<Object?> get props => [];
}

class MemberLoading extends MemberState {
  const MemberLoading();
  @override
  List<Object?> get props => [];
}

class MemberLoaded extends MemberState {
  final List<FlatMemberEntity> members;
  final Set<String> exitInProgressIds;

  const MemberLoaded({
    required this.members,
    this.exitInProgressIds = const {},
  });

  bool get hasCoManager => members.any((m) => m.isCoManager);

  @override
  List<Object?> get props => [members, exitInProgressIds];
}

class MemberActionLoading extends MemberState {
  final List<FlatMemberEntity> members;
  final Set<String> exitInProgressIds;

  const MemberActionLoading({
    required this.members,
    required this.exitInProgressIds,
  });

  @override
  List<Object?> get props => [members, exitInProgressIds];
}

/// Initial load failed — no data to show.
class MemberError extends MemberState {
  final String message;

  const MemberError(this.message);

  @override
  List<Object?> get props => [message];
}

/// An action failed but we still have member data to display.
class MemberActionError extends MemberState {
  final String message;
  final List<FlatMemberEntity> members;
  final Set<String> exitInProgressIds;

  const MemberActionError({
    required this.message,
    required this.members,
    required this.exitInProgressIds,
  });

  @override
  List<Object?> get props => [message, members, exitInProgressIds];
}

/// Settlement ready — list page navigates to settlement screen.
class MemberSettlementReady extends MemberState {
  final List<FlatMemberEntity> members;
  final Set<String> exitInProgressIds;
  final SettlementEntity settlement;
  final String memberId;

  const MemberSettlementReady({
    required this.members,
    required this.exitInProgressIds,
    required this.settlement,
    required this.memberId,
  });

  @override
  List<Object?> get props => [members, exitInProgressIds, settlement, memberId];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

class MemberCubit extends Cubit<MemberState> {
  final GetMembersUseCase _getMembers;
  final ChangeRoleUseCase _changeRole;
  final TransferManagerUseCase _transferManager;
  final InitiateExitUseCase _initiateExit;
  final GetSettlementUseCase _getSettlement;
  final FinalizeExitUseCase _finalizeExit;
  final CancelExitUseCase _cancelExit;

  MemberCubit({
    required GetMembersUseCase getMembers,
    required ChangeRoleUseCase changeRole,
    required TransferManagerUseCase transferManager,
    required InitiateExitUseCase initiateExit,
    required GetSettlementUseCase getSettlement,
    required FinalizeExitUseCase finalizeExit,
    required CancelExitUseCase cancelExit,
  }) : _getMembers = getMembers,
       _changeRole = changeRole,
       _transferManager = transferManager,
       _initiateExit = initiateExit,
       _getSettlement = getSettlement,
       _finalizeExit = finalizeExit,
       _cancelExit = cancelExit,
       super(const MemberInitial());

  Future<void> load(String flatId) async {
    emit(const MemberLoading());
    try {
      final members = await _getMembers(flatId);
      emit(MemberLoaded(members: members));
    } catch (e) {
      emit(MemberError(_msg(e)));
    }
  }

  Future<void> changeRole({
    required String flatId,
    required String memberId,
    required String role,
  }) async {
    final current = _loaded;
    if (current == null) return;
    emit(MemberActionLoading(members: current.members, exitInProgressIds: current.exitInProgressIds));
    try {
      await _changeRole(flatId: flatId, memberId: memberId, role: role);
      final members = await _getMembers(flatId);
      emit(MemberLoaded(members: members, exitInProgressIds: current.exitInProgressIds));
    } catch (e) {
      emit(current);
      emit(MemberActionError(message: _msg(e), members: current.members, exitInProgressIds: current.exitInProgressIds));
    }
  }

  Future<void> transferManager({
    required String flatId,
    required String newManagerId,
  }) async {
    final current = _loaded;
    if (current == null) return;
    emit(MemberActionLoading(members: current.members, exitInProgressIds: current.exitInProgressIds));
    try {
      await _transferManager(flatId: flatId, newManagerId: newManagerId);
      final members = await _getMembers(flatId);
      emit(MemberLoaded(members: members, exitInProgressIds: current.exitInProgressIds));
    } catch (e) {
      emit(current);
      emit(MemberActionError(message: _msg(e), members: current.members, exitInProgressIds: current.exitInProgressIds));
    }
  }

  Future<void> initiateExit({
    required String flatId,
    required String memberId,
    double fixedRefund = 0,
  }) async {
    final current = _loaded;
    if (current == null) return;
    emit(MemberActionLoading(members: current.members, exitInProgressIds: current.exitInProgressIds));
    try {
      final settlement = await _initiateExit(
        flatId: flatId,
        memberId: memberId,
        fixedRefund: fixedRefund,
      );
      final newExitIds = {...current.exitInProgressIds, memberId};
      emit(MemberSettlementReady(
        members: current.members,
        exitInProgressIds: newExitIds,
        settlement: settlement,
        memberId: memberId,
      ));
    } catch (e) {
      // 409 = exit already in progress — load the existing settlement instead
      if (e is ServerException && e.statusCode == 409) {
        try {
          final settlement = await _getSettlement(flatId: flatId, memberId: memberId);
          final newExitIds = {...current.exitInProgressIds, memberId};
          emit(MemberSettlementReady(
            members: current.members,
            exitInProgressIds: newExitIds,
            settlement: settlement,
            memberId: memberId,
          ));
          return;
        } catch (_) {
          // fall through to generic error
        }
      }
      emit(current);
      emit(MemberActionError(message: _msg(e), members: current.members, exitInProgressIds: current.exitInProgressIds));
    }
  }

  Future<void> viewSettlement({
    required String flatId,
    required String memberId,
  }) async {
    final current = _loaded;
    if (current == null) return;
    emit(MemberActionLoading(members: current.members, exitInProgressIds: current.exitInProgressIds));
    try {
      final settlement = await _getSettlement(flatId: flatId, memberId: memberId);
      final newExitIds = {...current.exitInProgressIds, memberId};
      emit(MemberSettlementReady(
        members: current.members,
        exitInProgressIds: newExitIds,
        settlement: settlement,
        memberId: memberId,
      ));
    } catch (e) {
      emit(current);
      emit(MemberActionError(message: _msg(e), members: current.members, exitInProgressIds: current.exitInProgressIds));
    }
  }

  void acknowledgeSettlement() {
    final s = state;
    if (s is MemberSettlementReady) {
      emit(MemberLoaded(members: s.members, exitInProgressIds: s.exitInProgressIds));
    }
  }

  Future<FinalizeExitEntity> finalizeExit({
    required String flatId,
    required String memberId,
  }) => _finalizeExit(flatId: flatId, memberId: memberId);

  Future<void> cancelExit({
    required String flatId,
    required String memberId,
  }) => _cancelExit(flatId: flatId, memberId: memberId);

  MemberLoaded? get _loaded {
    final s = state;
    if (s is MemberLoaded) return s;
    if (s is MemberActionLoading) {
      return MemberLoaded(members: s.members, exitInProgressIds: s.exitInProgressIds);
    }
    if (s is MemberSettlementReady) {
      return MemberLoaded(members: s.members, exitInProgressIds: s.exitInProgressIds);
    }
    return null;
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
