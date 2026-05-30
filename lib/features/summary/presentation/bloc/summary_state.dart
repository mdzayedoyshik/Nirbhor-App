import 'package:equatable/equatable.dart';

import '../../domain/entities/close_preview_entity.dart';
import '../../domain/entities/closed_month_entity.dart';
import '../../domain/entities/month_summary_entity.dart';

abstract class SummaryState extends Equatable {
  const SummaryState();
}

class SummaryInitial extends SummaryState {
  const SummaryInitial();

  @override
  List<Object?> get props => [];
}

class SummaryLoading extends SummaryState {
  const SummaryLoading();

  @override
  List<Object?> get props => [];
}

class SummaryLoaded extends SummaryState {
  const SummaryLoaded({
    required this.summary,
    required this.closedMonths,
    this.isClosedMonthsLoading = false,
    this.isPreviewLoading = false,
    this.preview,
    this.isClosing = false,
  });

  final MonthSummaryEntity summary;
  final List<ClosedMonthEntity> closedMonths;
  final bool isClosedMonthsLoading;
  final bool isPreviewLoading;
  final ClosePreviewEntity? preview;
  final bool isClosing;

  SummaryLoaded copyWith({
    MonthSummaryEntity? summary,
    List<ClosedMonthEntity>? closedMonths,
    bool? isClosedMonthsLoading,
    bool? isPreviewLoading,
    ClosePreviewEntity? preview,
    bool? isClosing,
    bool clearPreview = false,
  }) =>
      SummaryLoaded(
        summary: summary ?? this.summary,
        closedMonths: closedMonths ?? this.closedMonths,
        isClosedMonthsLoading:
            isClosedMonthsLoading ?? this.isClosedMonthsLoading,
        isPreviewLoading: isPreviewLoading ?? this.isPreviewLoading,
        preview: clearPreview ? null : (preview ?? this.preview),
        isClosing: isClosing ?? this.isClosing,
      );

  @override
  List<Object?> get props => [
        summary,
        closedMonths,
        isClosedMonthsLoading,
        isPreviewLoading,
        preview,
        isClosing,
      ];
}

class SummaryError extends SummaryState {
  const SummaryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class SummaryCloseSuccess extends SummaryState {
  const SummaryCloseSuccess({
    required this.summary,
    required this.closedMonths,
    required this.month,
    required this.year,
  });

  final MonthSummaryEntity summary;
  final List<ClosedMonthEntity> closedMonths;
  final int month;
  final int year;

  @override
  List<Object?> get props => [month, year];
}

class SummaryCloseError extends SummaryState {
  const SummaryCloseError({
    required this.message,
    required this.summary,
    required this.closedMonths,
    this.isUnapprovedConflict = false,
    this.unapprovedCount = 0,
  });

  final String message;
  final MonthSummaryEntity summary;
  final List<ClosedMonthEntity> closedMonths;
  final bool isUnapprovedConflict;
  final int unapprovedCount;

  @override
  List<Object?> get props => [message, isUnapprovedConflict, unapprovedCount];
}
