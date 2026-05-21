import 'package:equatable/equatable.dart';

abstract class FlatPreviewEvent extends Equatable {
  const FlatPreviewEvent();
  @override
  List<Object?> get props => [];
}

class FlatPreviewLoadRequested extends FlatPreviewEvent {
  final String code;

  const FlatPreviewLoadRequested(this.code);

  @override
  List<Object?> get props => [code];
}

class FlatPreviewResetRequested extends FlatPreviewEvent {
  const FlatPreviewResetRequested();
}
