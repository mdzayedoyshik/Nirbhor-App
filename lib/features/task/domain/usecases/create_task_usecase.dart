import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class CreateTaskUseCase {
  const CreateTaskUseCase(this._repo);
  final TaskRepository _repo;

  Future<TaskEntity> call({
    required String flatId,
    required String title,
    String? description,
    String? assignedTo,
    String? dueDate,
    List<String>? subTaskTitles,
  }) =>
      _repo.createTask(
        flatId: flatId,
        title: title,
        description: description,
        assignedTo: assignedTo,
        dueDate: dueDate,
        subTaskTitles: subTaskTitles,
      );
}
