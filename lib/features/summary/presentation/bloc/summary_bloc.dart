import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/closed_month_entity.dart';
import '../../domain/usecases/close_month_usecase.dart';
import '../../domain/usecases/get_close_preview_usecase.dart';
import '../../domain/usecases/get_closed_months_usecase.dart';
import '../../domain/usecases/get_monthly_summary_usecase.dart';
import 'summary_event.dart';
import 'summary_state.dart';

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  SummaryBloc({
    required GetMonthlySummaryUseCase getMonthlySummary,
    required GetClosePreviewUseCase getClosePreview,
    required CloseMonthUseCase closeMonth,
    required GetClosedMonthsUseCase getClosedMonths,
  })  : _getMonthlySummary = getMonthlySummary,
        _getClosePreview = getClosePreview,
        _closeMonth = closeMonth,
        _getClosedMonths = getClosedMonths,
        super(const SummaryInitial()) {
    on<SummaryLoadRequested>(_onLoad);
    on<SummaryClosedMonthsLoadRequested>(_onLoadClosedMonths);
    on<SummaryPreviewRequested>(_onPreview);
    on<SummaryCloseMonthRequested>(_onClose);
  }

  final GetMonthlySummaryUseCase _getMonthlySummary;
  final GetClosePreviewUseCase _getClosePreview;
  final CloseMonthUseCase _closeMonth;
  final GetClosedMonthsUseCase _getClosedMonths;

  Future<void> _onLoad(
      SummaryLoadRequested event, Emitter<SummaryState> emit) async {
    final current = state;
    if (current is SummaryLoaded) {
      // If same month already loaded, just refresh silently
      if (current.summary.month == event.month &&
          current.summary.year == event.year) {
        try {
          final summary = await _getMonthlySummary(
              event.flatId, event.month, event.year);
          emit(current.copyWith(summary: summary));
        } catch (_) {}
        return;
      }
      // Different month: show loading overlay but keep old data visible briefly
      emit(current.copyWith(isClosing: false, clearPreview: true));
    } else {
      emit(const SummaryLoading());
    }

    try {
      final summary =
          await _getMonthlySummary(event.flatId, event.month, event.year);
      final existingMonths = state is SummaryLoaded
          ? (state as SummaryLoaded).closedMonths
          : <ClosedMonthEntity>[];

      List<ClosedMonthEntity> closedMonths;
      if (existingMonths.isEmpty) {
        try {
          closedMonths = await _getClosedMonths(event.flatId);
        } catch (_) {
          closedMonths = [];
        }
      } else {
        closedMonths = existingMonths;
      }

      emit(SummaryLoaded(summary: summary, closedMonths: closedMonths));
    } catch (e) {
      emit(SummaryError(_msg(e)));
    }
  }

  Future<void> _onLoadClosedMonths(
      SummaryClosedMonthsLoadRequested event,
      Emitter<SummaryState> emit) async {
    final current = state;
    if (current is! SummaryLoaded) return;

    emit(current.copyWith(isClosedMonthsLoading: true));
    try {
      final months = await _getClosedMonths(event.flatId);
      emit(current.copyWith(closedMonths: months, isClosedMonthsLoading: false));
    } catch (_) {
      emit(current.copyWith(isClosedMonthsLoading: false));
    }
  }

  Future<void> _onPreview(
      SummaryPreviewRequested event, Emitter<SummaryState> emit) async {
    final current = state;
    if (current is! SummaryLoaded) return;

    emit(current.copyWith(isPreviewLoading: true, clearPreview: true));
    try {
      final preview = await _getClosePreview(event.flatId);
      emit(current.copyWith(isPreviewLoading: false, preview: preview));
    } catch (e) {
      emit(current.copyWith(isPreviewLoading: false));
    }
  }

  Future<void> _onClose(
      SummaryCloseMonthRequested event, Emitter<SummaryState> emit) async {
    final current = state;
    if (current is! SummaryLoaded) return;

    emit(current.copyWith(isClosing: true));
    try {
      await _closeMonth(event.flatId, event.month, event.year,
          force: event.force);

      final newSummary =
          await _getMonthlySummary(event.flatId, event.month, event.year);
      final newClosedMonths = await _getClosedMonths(event.flatId);

      emit(SummaryCloseSuccess(
        summary: newSummary,
        closedMonths: newClosedMonths,
        month: event.month,
        year: event.year,
      ));
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        // Try parsing structured error for unapproved expenses
        int unapprovedCount = 0;
        bool isConflict = false;
        try {
          final parsed = jsonDecode(e.message) as Map<String, dynamic>;
          unapprovedCount = (parsed['unapproved_count'] as num?)?.toInt() ?? 0;
          isConflict = unapprovedCount > 0;
        } catch (_) {}

        emit(SummaryCloseError(
          message: isConflict
              ? '$unapprovedCount unapproved expense(s) found. Force close to proceed.'
              : e.message,
          summary: current.summary,
          closedMonths: current.closedMonths,
          isUnapprovedConflict: isConflict,
          unapprovedCount: unapprovedCount,
        ));
      } else {
        emit(SummaryCloseError(
          message: _msg(e),
          summary: current.summary,
          closedMonths: current.closedMonths,
        ));
      }
    }
  }

  String _msg(Object e) {
    if (e is ServerException) return e.message;
    if (e is NetworkException) return e.toString();
    return 'Something went wrong. Please try again.';
  }
}
