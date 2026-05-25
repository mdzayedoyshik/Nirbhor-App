import '../repositories/task_repository.dart';

class GetTasksUseCase {
  const GetTasksUseCase(this._repo);
  final TaskRepository _repo;

  Future<Map<String, dynamic>> call(
    String flatId, {
    String? status,
    String? assignedTo,
    String? dueBefore,
    String? dueAfter,
    int page = 1,
    int limit = 20,
  }) =>
      _repo.getTasks(
        flatId,
        status: status,
        assignedTo: assignedTo,
        dueBefore: dueBefore,
        dueAfter: dueAfter,
        page: page,
        limit: limit,
      );
}
