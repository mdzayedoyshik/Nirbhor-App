abstract class FeedbackRepository {
  Future<void> submitFeedback({
    required String type,
    String? title,
    required String description,
    String? appVersion,
  });
}
