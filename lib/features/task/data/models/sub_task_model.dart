import '../../domain/entities/sub_task_entity.dart';

class SubTaskModel extends SubTaskEntity {
  const SubTaskModel({
    required super.id,
    required super.taskId,
    required super.title,
    required super.isCompleted,
    required super.createdAt,
  });

  factory SubTaskModel.fromJson(Map<String, dynamic> json) => SubTaskModel(
        id: json['id'] as String,
        taskId: json['task_id'] as String,
        title: json['title'] as String,
        isCompleted: (json['is_completed'] as bool?) ?? false,
        createdAt: json['created_at'] as String? ?? '',
      );
}
