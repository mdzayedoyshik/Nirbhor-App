import 'package:equatable/equatable.dart';

abstract class MemberEvent extends Equatable {
  const MemberEvent();
  @override
  List<Object?> get props => [];
}

class MemberLoadRequested extends MemberEvent {
  final String flatId;

  const MemberLoadRequested(this.flatId);

  @override
  List<Object?> get props => [flatId];
}

class MemberRoleChangeRequested extends MemberEvent {
  final String flatId;
  final String memberId;
  final String role;

  const MemberRoleChangeRequested({
    required this.flatId,
    required this.memberId,
    required this.role,
  });

  @override
  List<Object?> get props => [flatId, memberId, role];
}

class ManagerTransferRequested extends MemberEvent {
  final String flatId;
  final String newManagerId;

  const ManagerTransferRequested({
    required this.flatId,
    required this.newManagerId,
  });

  @override
  List<Object?> get props => [flatId, newManagerId];
}

class MemberExitInitiateRequested extends MemberEvent {
  final String flatId;
  final String memberId;
  final double fixedRefund;

  const MemberExitInitiateRequested({
    required this.flatId,
    required this.memberId,
    this.fixedRefund = 0,
  });

  @override
  List<Object?> get props => [flatId, memberId, fixedRefund];
}

class MemberSettlementViewRequested extends MemberEvent {
  final String flatId;
  final String memberId;

  const MemberSettlementViewRequested({
    required this.flatId,
    required this.memberId,
  });

  @override
  List<Object?> get props => [flatId, memberId];
}

class MemberSettlementAcknowledged extends MemberEvent {
  const MemberSettlementAcknowledged();
}
