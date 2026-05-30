import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/complaint_entity.dart';
import '../../domain/usecases/delete_complaint_usecase.dart';
import '../../domain/usecases/edit_complaint_usecase.dart';
import '../../domain/usecases/get_complaint_usecase.dart';
import '../../domain/usecases/get_complaints_usecase.dart';
import '../../domain/usecases/raise_complaint_usecase.dart';
import '../../domain/usecases/update_complaint_status_usecase.dart';

part 'complaint_event.dart';
part 'complaint_state.dart';

class ComplaintBloc extends Bloc<ComplaintEvent, ComplaintState> {
  ComplaintBloc({
    required GetComplaintsUseCase getComplaints,
    required GetComplaintUseCase getComplaint,
    required RaiseComplaintUseCase raiseComplaint,
    required UpdateComplaintStatusUseCase updateStatus,
    required EditComplaintUseCase editComplaint,
    required DeleteComplaintUseCase deleteComplaint,
  })  : _getComplaints = getComplaints,
        _getComplaint = getComplaint,
        _raiseComplaint = raiseComplaint,
        _updateStatus = updateStatus,
        _editComplaint = editComplaint,
        _deleteComplaint = deleteComplaint,
        super(const ComplaintInitial()) {
    on<ComplaintsLoadRequested>(_onLoad);
    on<ComplaintsLoadMoreRequested>(_onLoadMore);
    on<ComplaintDetailRequested>(_onDetail);
    on<ComplaintRaiseRequested>(_onRaise);
    on<ComplaintStatusUpdateRequested>(_onUpdateStatus);
    on<ComplaintEditRequested>(_onEdit);
    on<ComplaintDeleteRequested>(_onDelete);
  }

  final GetComplaintsUseCase _getComplaints;
  final GetComplaintUseCase _getComplaint;
  final RaiseComplaintUseCase _raiseComplaint;
  final UpdateComplaintStatusUseCase _updateStatus;
  final EditComplaintUseCase _editComplaint;
  final DeleteComplaintUseCase _deleteComplaint;

  // ── Load list ──────────────────────────────────────────────────────────────

  Future<void> _onLoad(
      ComplaintsLoadRequested event, Emitter<ComplaintState> emit) async {
    emit(const ComplaintListLoading());
    try {
      final result = await _getComplaints(
        event.flatId,
        status: event.status,
        raisedBy: event.raisedBy,
      );
      emit(ComplaintListLoaded(
        complaints: List<ComplaintEntity>.from(result['complaints'] as List),
        pagination: result['pagination'] as Map<String, dynamic>,
      ));
    } catch (e) {
      emit(ComplaintError(_msg(e)));
    }
  }

  // ── Load more ──────────────────────────────────────────────────────────────

  Future<void> _onLoadMore(
      ComplaintsLoadMoreRequested event, Emitter<ComplaintState> emit) async {
    final current = state;
    if (current is! ComplaintListLoaded || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final result = await _getComplaints(
        event.flatId,
        status: event.status,
        raisedBy: event.raisedBy,
        page: event.nextPage,
      );
      final more =
          List<ComplaintEntity>.from(result['complaints'] as List);
      emit(ComplaintListLoaded(
        complaints: [...current.complaints, ...more],
        pagination: result['pagination'] as Map<String, dynamic>,
      ));
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  // ── Detail ─────────────────────────────────────────────────────────────────

  Future<void> _onDetail(
      ComplaintDetailRequested event, Emitter<ComplaintState> emit) async {
    emit(const ComplaintDetailLoading());
    try {
      final c = await _getComplaint(event.flatId, event.complaintId);
      emit(ComplaintDetailLoaded(c));
    } catch (e) {
      emit(ComplaintError(_msg(e)));
    }
  }

  // ── Raise ──────────────────────────────────────────────────────────────────

  Future<void> _onRaise(
      ComplaintRaiseRequested event, Emitter<ComplaintState> emit) async {
    emit(const ComplaintActionLoading());
    try {
      await _raiseComplaint(
        flatId: event.flatId,
        subject: event.subject,
        description: event.description,
      );
      emit(const ComplaintActionSuccess('Complaint raised'));
    } catch (e) {
      emit(ComplaintError(_msg(e)));
    }
  }

  // ── Update Status ──────────────────────────────────────────────────────────

  Future<void> _onUpdateStatus(
      ComplaintStatusUpdateRequested event,
      Emitter<ComplaintState> emit) async {
    final prevDetail =
        state is ComplaintDetailLoaded
            ? (state as ComplaintDetailLoaded).complaint
            : null;
    emit(ComplaintActionLoading(detail: prevDetail));
    try {
      final updated = await _updateStatus(
        flatId: event.flatId,
        complaintId: event.complaintId,
        status: event.status,
      );
      emit(const ComplaintActionSuccess('Status updated'));
      emit(ComplaintDetailLoaded(updated));
    } catch (e) {
      emit(ComplaintError(_msg(e), detail: prevDetail));
      if (prevDetail != null) emit(ComplaintDetailLoaded(prevDetail));
    }
  }

  // ── Edit ───────────────────────────────────────────────────────────────────

  Future<void> _onEdit(
      ComplaintEditRequested event, Emitter<ComplaintState> emit) async {
    final prevDetail =
        state is ComplaintDetailLoaded
            ? (state as ComplaintDetailLoaded).complaint
            : null;
    emit(ComplaintActionLoading(detail: prevDetail));
    try {
      final updated = await _editComplaint(
        flatId: event.flatId,
        complaintId: event.complaintId,
        subject: event.subject,
        description: event.description,
      );
      emit(const ComplaintActionSuccess('Complaint updated'));
      emit(ComplaintDetailLoaded(updated));
    } catch (e) {
      emit(ComplaintError(_msg(e), detail: prevDetail));
      if (prevDetail != null) emit(ComplaintDetailLoaded(prevDetail));
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _onDelete(
      ComplaintDeleteRequested event, Emitter<ComplaintState> emit) async {
    emit(const ComplaintActionLoading());
    try {
      await _deleteComplaint(event.flatId, event.complaintId);
      emit(const ComplaintActionSuccess('Complaint deleted'));
    } catch (e) {
      emit(ComplaintError(_msg(e)));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _msg(Object e) {
    final s = e.toString();
    if (s.contains('ServerException')) {
      final match = RegExp(r'message: (.+?)\)').firstMatch(s);
      return match?.group(1) ?? 'Something went wrong';
    }
    return 'Something went wrong';
  }
}
