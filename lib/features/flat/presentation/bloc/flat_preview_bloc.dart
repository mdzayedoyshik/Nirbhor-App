import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/usecases/preview_flat_usecase.dart';
import 'flat_preview_event.dart';
import 'flat_preview_state.dart';

export 'flat_preview_event.dart';
export 'flat_preview_state.dart';

class FlatPreviewBloc extends Bloc<FlatPreviewEvent, FlatPreviewState> {
  final PreviewFlatUseCase _preview;

  FlatPreviewBloc({required PreviewFlatUseCase preview})
      : _preview = preview,
        super(const FlatPreviewInitial()) {
    on<FlatPreviewLoadRequested>(_onLoad);
    on<FlatPreviewResetRequested>(_onReset);
  }

  Future<void> _onLoad(
    FlatPreviewLoadRequested event,
    Emitter<FlatPreviewState> emit,
  ) async {
    final code = event.code.trim();
    if (code.isEmpty) return;
    emit(const FlatPreviewLoading());
    try {
      final result = await _preview(code.toUpperCase());
      emit(FlatPreviewLoaded(result));
    } catch (e) {
      emit(FlatPreviewError(_message(e)));
    }
  }

  void _onReset(
    FlatPreviewResetRequested event,
    Emitter<FlatPreviewState> emit,
  ) {
    emit(const FlatPreviewInitial());
  }

  String _message(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
