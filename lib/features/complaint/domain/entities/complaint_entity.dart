import 'package:equatable/equatable.dart';

class ComplaintEntity extends Equatable {
  const ComplaintEntity({
    required this.id,
    required this.flatId,
    required this.raisedBy,
    required this.raisedByName,
    required this.subject,
    required this.status,
    required this.createdAt,
    this.description,
    this.resolvedAt,
  });

  final String id;
  final String flatId;
  final String raisedBy; // flat_member id
  final String raisedByName;
  final String subject;
  final String status; // open | in_progress | resolved
  final String createdAt;
  final String? description; // only in detail view
  final String? resolvedAt;

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';

  @override
  List<Object?> get props => [
        id, flatId, raisedBy, raisedByName, subject, status,
        createdAt, description, resolvedAt,
      ];
}
