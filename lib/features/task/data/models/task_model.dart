import '../../domain/entities/task_entity.dart';
import 'sub_task_model.dart';

class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.flatId,
    required super.title,
    super.description,
    super.assignedTo,
    super.assignedToName,
    super.assignees = const [],
    required super.createdBy,
    required super.createdByName,
    required super.status,
    super.dueDate,
    required super.createdAt,
    required super.updatedAt,
    super.completedAt,
    super.subTaskCount,
    super.subTasksCompleted,
    super.subTasks,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final hasSubTasksList = json.containsKey('sub_tasks');
    final rawAssignees = json['assignees'] as List<dynamic>? ?? [];
    return TaskModel(
      id: json['id'] as String,
      flatId: json['flat_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      assignedTo: json['assigned_to'] as String?,
      assignedToName: json['assigned_to_name'] as String?,
      assignees: rawAssignees
          .map((a) => TaskAssigneeEntity(
                flatMemberId: a['flat_member_id'] as String,
                name: a['name'] as String?,
              ))
          .toList(),
      createdBy: json['created_by'] as String,
      createdByName: json['created_by_name'] as String? ?? '',
      status: json['status'] as String,
      dueDate: json['due_date'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      completedAt: json['completed_at'] as String?,
      subTaskCount: json['sub_task_count'] as int?,
      subTasksCompleted: json['sub_tasks_completed'] as int?,
      subTasks: hasSubTasksList
          ? (json['sub_tasks'] as List)
              .map((s) => SubTaskModel.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}
