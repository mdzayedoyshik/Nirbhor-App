import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class UpdateTaskUseCase {
  const UpdateTaskUseCase(this._repo);
  final TaskRepository _repo;

  Future<TaskEntity> call({
    required String flatId,
    required String taskId,
    String? title,
    String? description,
    String? assignedTo,
    List<String>? assignedToIds,
    String? dueDate,
    bool clearAssignee = false,
    bool clearDueDate = false,
    String? status,
  }) =>
      _repo.updateTask(
        flatId: flatId,
        taskId: taskId,
        title: title,
        description: description,
        assignedTo: assignedTo,
        assignedToIds: assignedToIds,
        dueDate: dueDate,
        clearAssignee: clearAssignee,
        clearDueDate: clearDueDate,
        status: status,
      );
}
