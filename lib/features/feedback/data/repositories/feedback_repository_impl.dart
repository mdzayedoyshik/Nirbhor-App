import '../../domain/repositories/feedback_repository.dart';
import '../datasources/feedback_remote_datasource.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  FeedbackRepositoryImpl({required FeedbackRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final FeedbackRemoteDataSource _dataSource;

  @override
  Future<void> submitFeedback({
    required String type,
    String? title,
    required String description,
    String? appVersion,
  }) =>
      _dataSource.submitFeedback(
        type: type,
        title: title,
        description: description,
        appVersion: appVersion,
      );
}
