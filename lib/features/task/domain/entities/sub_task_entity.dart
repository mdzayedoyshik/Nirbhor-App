import 'package:equatable/equatable.dart';

class SubTaskEntity extends Equatable {
  const SubTaskEntity({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final String createdAt;

  @override
  List<Object?> get props => [id, taskId, title, isCompleted, createdAt];
}
