part of 'join_requests_cubit.dart';

abstract class JoinRequestsState extends Equatable {
  const JoinRequestsState();
  @override
  List<Object?> get props => [];
}

class JoinRequestsInitial extends JoinRequestsState {
  const JoinRequestsInitial();
}

class JoinRequestsLoading extends JoinRequestsState {
  const JoinRequestsLoading();
}

class JoinRequestsLoaded extends JoinRequestsState {
  final List<JoinRequestEntity> requests;
  const JoinRequestsLoaded(this.requests);
  @override
  List<Object?> get props => [requests];
}

class JoinRequestsError extends JoinRequestsState {
  final String message;
  const JoinRequestsError(this.message);
  @override
  List<Object?> get props => [message];
}

/// A specific request action (approve/decline) is in progress
class JoinRequestsActionLoading extends JoinRequestsState {
  final String requestId;
  const JoinRequestsActionLoading(this.requestId);
  @override
  List<Object?> get props => [requestId];
}

/// A specific request action failed
class JoinRequestsActionError extends JoinRequestsState {
  final String requestId;
  final String message;
  const JoinRequestsActionError(this.requestId, this.message);
  @override
  List<Object?> get props => [requestId, message];
}
