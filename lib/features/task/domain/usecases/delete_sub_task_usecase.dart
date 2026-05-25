import '../repositories/task_repository.dart';

class DeleteSubTaskUseCase {
  const DeleteSubTaskUseCase(this._repo);
  final TaskRepository _repo;

  Future<void> call({
    required String flatId,
    required String taskId,
    required String subTaskId,
  }) =>
      _repo.deleteSubTask(flatId: flatId, taskId: taskId, subTaskId: subTaskId);
}
