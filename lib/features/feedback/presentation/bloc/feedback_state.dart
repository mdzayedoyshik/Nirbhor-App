part of 'feedback_bloc.dart';

abstract class FeedbackState extends Equatable {
  const FeedbackState();
  @override
  List<Object?> get props => [];
}

class FeedbackInitial extends FeedbackState {
  const FeedbackInitial();
}

class FeedbackLoading extends FeedbackState {
  const FeedbackLoading();
}

class FeedbackSuccess extends FeedbackState {
  const FeedbackSuccess();
}

class FeedbackError extends FeedbackState {
  const FeedbackError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
