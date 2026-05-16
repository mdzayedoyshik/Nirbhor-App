part of 'flat_preview_cubit.dart';

abstract class FlatPreviewState extends Equatable {
  const FlatPreviewState();
  @override
  List<Object?> get props => [];
}

class FlatPreviewInitial extends FlatPreviewState {
  const FlatPreviewInitial();
}

class FlatPreviewLoading extends FlatPreviewState {
  const FlatPreviewLoading();
}

class FlatPreviewLoaded extends FlatPreviewState {
  final FlatPreviewEntity preview;
  const FlatPreviewLoaded(this.preview);
  @override
  List<Object?> get props => [preview];
}

class FlatPreviewError extends FlatPreviewState {
  final String message;
  const FlatPreviewError(this.message);
  @override
  List<Object?> get props => [message];
}
