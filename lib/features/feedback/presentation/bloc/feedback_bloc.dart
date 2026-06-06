import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/usecases/submit_feedback_usecase.dart';

part 'feedback_event.dart';
part 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  FeedbackBloc({required SubmitFeedbackUseCase submitFeedback})
      : _submit = submitFeedback,
        super(const FeedbackInitial()) {
    on<FeedbackSubmitRequested>(_onSubmit);
  }

  final SubmitFeedbackUseCase _submit;

  Future<void> _onSubmit(
    FeedbackSubmitRequested event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(const FeedbackLoading());
    try {
      final info = await PackageInfo.fromPlatform();
      final appVersion = '${info.version}+${info.buildNumber}';
      await _submit(
        type: event.type,
        title: event.title,
        description: event.description,
        appVersion: appVersion,
      );
      emit(const FeedbackSuccess());
    } catch (e) {
      emit(FeedbackError(_msg(e)));
    }
  }

  String _msg(Object e) {
    final s = e.toString();
    if (s.contains('ServerException')) {
      final match = RegExp(r'message: (.+?)\)').firstMatch(s);
      return match?.group(1) ?? 'Something went wrong';
    }
    return 'Something went wrong';
  }
}
