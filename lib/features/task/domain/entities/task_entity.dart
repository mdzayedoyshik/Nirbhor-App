import 'package:equatable/equatable.dart';
import 'sub_task_entity.dart';

class TaskAssigneeEntity extends Equatable {
  const TaskAssigneeEntity({
    required this.flatMemberId,
    required this.name,
    this.photoUrl,
  });

  final String flatMemberId;
  final String? name;
  final String? photoUrl;

  @override
  List<Object?> get props => [flatMemberId, name, photoUrl];
}

class TaskEntity extends Equatable {
  const TaskEntity({
    required this.id,
    required this.flatId,
    required this.title,
    this.description,
    this.assignedTo,
    this.assignedToName,
    this.assignees = const [],
    required this.createdBy,
    required this.createdByName,
    required this.status,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    // List view fields (null in detail view)
    this.subTaskCount,
    this.subTasksCompleted,
    // Detail view field (null in list view)
    this.subTasks,
  });

  final String id;
  final String flatId;
  final String title;
  final String? description;
  final String? assignedTo;
  final String? assignedToName;
  final List<TaskAssigneeEntity> assignees;
  final String createdBy;
  final String createdByName;
  final String status; // pending | in_progress | completed
  final String? dueDate;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;

  // List view
  final int? subTaskCount;
  final int? subTasksCompleted;

  // Detail view
  final List<SubTaskEntity>? subTasks;

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    try {
      final due = DateTime.parse(dueDate!);
      return DateTime.now().isAfter(due);
    } catch (_) {
      return false;
    }
  }

  @override
  List<Object?> get props => [
        id, flatId, title, description, assignedTo, assignedToName, assignees,
        createdBy, createdByName, status, dueDate, createdAt, updatedAt,
        completedAt, subTaskCount, subTasksCompleted, subTasks,
      ];
}
