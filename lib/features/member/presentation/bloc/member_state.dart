import 'package:equatable/equatable.dart';

import '../../../flat/domain/entities/flat_member_entity.dart';
import '../../domain/entities/settlement_entity.dart';

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

/// An action is in progress; list stays visible.
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

/// Initial load failed — show retry screen.
class MemberLoadError extends MemberState {
  final String message;

  const MemberLoadError(this.message);

  @override
  List<Object?> get props => [message];
}

/// An action failed — list retained; listener shows snackbar.
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
