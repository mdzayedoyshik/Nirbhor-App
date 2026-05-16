import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/flat_preview_entity.dart';
import '../../domain/usecases/preview_flat_usecase.dart';

part 'flat_preview_state.dart';

class FlatPreviewCubit extends Cubit<FlatPreviewState> {
  final PreviewFlatUseCase _preview;

  FlatPreviewCubit({required PreviewFlatUseCase preview})
    : _preview = preview,
      super(const FlatPreviewInitial());

  Future<void> loadPreview(String code) async {
    if (code.trim().isEmpty) return;
    emit(const FlatPreviewLoading());
    try {
      final preview = await _preview(code.trim().toUpperCase());
      emit(FlatPreviewLoaded(preview));
    } catch (e) {
      emit(FlatPreviewError(_message(e)));
    }
  }

  void reset() => emit(const FlatPreviewInitial());

  String _message(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
