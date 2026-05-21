import 'package:equatable/equatable.dart';

abstract class JoinRequestsEvent extends Equatable {
  const JoinRequestsEvent();
  @override
  List<Object?> get props => [];
}

class JoinRequestsLoadRequested extends JoinRequestsEvent {
  final String flatId;

  const JoinRequestsLoadRequested(this.flatId);

  @override
  List<Object?> get props => [flatId];
}

class JoinRequestApproveRequested extends JoinRequestsEvent {
  final String flatId;
  final String requestId;
  final double fixedContribution;

  const JoinRequestApproveRequested({
    required this.flatId,
    required this.requestId,
    required this.fixedContribution,
  });

  @override
  List<Object?> get props => [flatId, requestId, fixedContribution];
}

class JoinRequestDeclineRequested extends JoinRequestsEvent {
  final String flatId;
  final String requestId;

  const JoinRequestDeclineRequested({
    required this.flatId,
    required this.requestId,
  });

  @override
  List<Object?> get props => [flatId, requestId];
}
