import '../entities/sub_task_entity.dart';
import '../repositories/task_repository.dart';

class AddSubTaskUseCase {
  const AddSubTaskUseCase(this._repo);
  final TaskRepository _repo;

  Future<SubTaskEntity> call({
    required String flatId,
    required String taskId,
    required String title,
  }) =>
      _repo.addSubTask(flatId: flatId, taskId: taskId, title: title);
}
