import '../repositories/feedback_repository.dart';

class SubmitFeedbackUseCase {
  SubmitFeedbackUseCase(this._repo);
  final FeedbackRepository _repo;

  Future<void> call({
    required String type,
    String? title,
    required String description,
    String? appVersion,
  }) =>
      _repo.submitFeedback(
        type: type,
        title: title,
        description: description,
        appVersion: appVersion,
      );
}
