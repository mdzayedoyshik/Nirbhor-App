part of 'feedback_bloc.dart';

abstract class FeedbackEvent extends Equatable {
  const FeedbackEvent();
  @override
  List<Object?> get props => [];
}

class FeedbackSubmitRequested extends FeedbackEvent {
  const FeedbackSubmitRequested({
    required this.type,
    this.title,
    required this.description,
  });

  final String type;
  final String? title;
  final String description;

  @override
  List<Object?> get props => [type, title, description];
}
