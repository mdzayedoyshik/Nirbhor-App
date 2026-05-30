part of 'complaint_bloc.dart';

abstract class ComplaintEvent extends Equatable {
  const ComplaintEvent();
  @override
  List<Object?> get props => [];
}

class ComplaintsLoadRequested extends ComplaintEvent {
  const ComplaintsLoadRequested(this.flatId, {this.status, this.raisedBy});
  final String flatId;
  final String? status;
  final String? raisedBy;
  @override
  List<Object?> get props => [flatId, status, raisedBy];
}

class ComplaintsLoadMoreRequested extends ComplaintEvent {
  const ComplaintsLoadMoreRequested(
    this.flatId, {
    this.status,
    this.raisedBy,
    required this.nextPage,
  });
  final String flatId;
  final String? status;
  final String? raisedBy;
  final int nextPage;
  @override
  List<Object?> get props => [flatId, status, raisedBy, nextPage];
}

class ComplaintDetailRequested extends ComplaintEvent {
  const ComplaintDetailRequested(this.flatId, this.complaintId);
  final String flatId;
  final String complaintId;
  @override
  List<Object?> get props => [flatId, complaintId];
}

class ComplaintRaiseRequested extends ComplaintEvent {
  const ComplaintRaiseRequested({
    required this.flatId,
    required this.subject,
    this.description,
  });
  final String flatId;
  final String subject;
  final String? description;
  @override
  List<Object?> get props => [flatId, subject, description];
}

class ComplaintStatusUpdateRequested extends ComplaintEvent {
  const ComplaintStatusUpdateRequested({
    required this.flatId,
    required this.complaintId,
    required this.status,
  });
  final String flatId;
  final String complaintId;
  final String status;
  @override
  List<Object?> get props => [flatId, complaintId, status];
}

class ComplaintEditRequested extends ComplaintEvent {
  const ComplaintEditRequested({
    required this.flatId,
    required this.complaintId,
    this.subject,
    this.description,
  });
  final String flatId;
  final String complaintId;
  final String? subject;
  final String? description;
  @override
  List<Object?> get props => [flatId, complaintId, subject, description];
}

class ComplaintDeleteRequested extends ComplaintEvent {
  const ComplaintDeleteRequested(this.flatId, this.complaintId);
  final String flatId;
  final String complaintId;
  @override
  List<Object?> get props => [flatId, complaintId];
}
