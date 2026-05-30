import '../repositories/task_repository.dart';

class DeleteTaskUseCase {
  const DeleteTaskUseCase(this._repo);
  final TaskRepository _repo;

  Future<void> call(String flatId, String taskId) =>
      _repo.deleteTask(flatId, taskId);
}
