import 'package:equatable/equatable.dart';

abstract class SummaryEvent extends Equatable {
  const SummaryEvent();
}

class SummaryLoadRequested extends SummaryEvent {
  const SummaryLoadRequested({
    required this.flatId,
    required this.month,
    required this.year,
  });

  final String flatId;
  final int month;
  final int year;

  @override
  List<Object?> get props => [flatId, month, year];
}

class SummaryClosedMonthsLoadRequested extends SummaryEvent {
  const SummaryClosedMonthsLoadRequested(this.flatId);

  final String flatId;

  @override
  List<Object?> get props => [flatId];
}

class SummaryPreviewRequested extends SummaryEvent {
  const SummaryPreviewRequested(this.flatId);

  final String flatId;

  @override
  List<Object?> get props => [flatId];
}

class SummaryCloseMonthRequested extends SummaryEvent {
  const SummaryCloseMonthRequested({
    required this.flatId,
    required this.month,
    required this.year,
    this.force = false,
  });

  final String flatId;
  final int month;
  final int year;
  final bool force;

  @override
  List<Object?> get props => [flatId, month, year, force];
}
