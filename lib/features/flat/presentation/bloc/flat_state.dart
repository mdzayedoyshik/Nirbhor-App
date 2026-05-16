part of 'flat_bloc.dart';

enum FlatLoadingSource {
  check,
  create,
  refresh,
  update,
  delete,
  join,
  cancelRequest,
}

abstract class FlatState extends Equatable {
  const FlatState();
  @override
  List<Object?> get props => [];
}

/// Before any check
class FlatInitial extends FlatState {
  const FlatInitial();
}

/// Initial session check in progress
class FlatChecking extends FlatState {
  const FlatChecking();
}

/// Action in progress; [base] is the state to render behind any loading indicator
class FlatActionLoading extends FlatState {
  final FlatLoadingSource source;
  final FlatState base;

  const FlatActionLoading(this.source, this.base);

  @override
  List<Object?> get props => [source, base];
}

/// User has no flat and no pending join request
class FlatNone extends FlatState {
  const FlatNone();
}

/// User has a pending join request awaiting manager approval
class FlatPendingRequest extends FlatState {
  final JoinRequestEntity request;
  const FlatPendingRequest(this.request);
  @override
  List<Object?> get props => [request];
}

/// User is an active member of a flat
class FlatLoaded extends FlatState {
  final FlatEntity flat;
  const FlatLoaded(this.flat);
  @override
  List<Object?> get props => [flat];
}

/// Error state — [fallback] is the state to render while the error is shown
class FlatError extends FlatState {
  final String message;
  final FlatState fallback;
  const FlatError(this.message, this.fallback);
  @override
  List<Object?> get props => [message, fallback];
}
