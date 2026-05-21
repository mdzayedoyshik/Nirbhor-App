import 'package:equatable/equatable.dart';

import '../../domain/entities/join_request_entity.dart';

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

/// A specific request action is in progress; list stays visible.
class JoinRequestsActionInProgress extends JoinRequestsState {
  final List<JoinRequestEntity> requests;
  final String requestId;

  const JoinRequestsActionInProgress({
    required this.requests,
    required this.requestId,
  });

  @override
  List<Object?> get props => [requests, requestId];
}

/// Initial load failed — show retry screen.
class JoinRequestsLoadError extends JoinRequestsState {
  final String message;

  const JoinRequestsLoadError(this.message);

  @override
  List<Object?> get props => [message];
}

/// An action failed — list retained; listener shows snackbar.
class JoinRequestsActionError extends JoinRequestsState {
  final List<JoinRequestEntity> requests;
  final String message;

  const JoinRequestsActionError({
    required this.requests,
    required this.message,
  });

  @override
  List<Object?> get props => [requests, message];
}
