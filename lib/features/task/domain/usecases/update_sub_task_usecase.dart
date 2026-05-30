import '../entities/sub_task_entity.dart';
import '../repositories/task_repository.dart';

class UpdateSubTaskUseCase {
  const UpdateSubTaskUseCase(this._repo);
  final TaskRepository _repo;

  Future<SubTaskEntity> call({
    required String flatId,
    required String taskId,
    required String subTaskId,
    String? title,
    bool? isCompleted,
  }) =>
      _repo.updateSubTask(
        flatId: flatId,
        taskId: taskId,
        subTaskId: subTaskId,
        title: title,
        isCompleted: isCompleted,
      );
}
