import '../entities/sub_task_entity.dart';
import '../entities/task_entity.dart';

abstract class TaskRepository {
  Future<Map<String, dynamic>> getTasks(
    String flatId, {
    String? status,
    String? assignedTo,
    String? dueBefore,
    String? dueAfter,
    int page = 1,
    int limit = 20,
  });

  Future<TaskEntity> getTask(String flatId, String taskId);

  Future<TaskEntity> createTask({
    required String flatId,
    required String title,
    String? description,
    String? assignedTo,
    String? dueDate,
    List<String>? subTaskTitles,
  });

  Future<TaskEntity> updateTask({
    required String flatId,
    required String taskId,
    String? title,
    String? description,
    String? assignedTo,
    String? dueDate,
    bool clearAssignee = false,
    bool clearDueDate = false,
    String? status,
  });

  Future<void> deleteTask(String flatId, String taskId);

  Future<SubTaskEntity> addSubTask({
    required String flatId,
    required String taskId,
    required String title,
  });

  Future<SubTaskEntity> updateSubTask({
    required String flatId,
    required String taskId,
    required String subTaskId,
    String? title,
    bool? isCompleted,
  });

  Future<void> deleteSubTask({
    required String flatId,
    required String taskId,
    required String subTaskId,
  });
}
