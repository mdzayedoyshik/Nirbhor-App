import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class GetTaskUseCase {
  const GetTaskUseCase(this._repo);
  final TaskRepository _repo;

  Future<TaskEntity> call(String flatId, String taskId) =>
      _repo.getTask(flatId, taskId);
}
