import '../../domain/entities/sub_task_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({required TaskRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final TaskRemoteDataSource _dataSource;

  @override
  Future<Map<String, dynamic>> getTasks(
    String flatId, {
    String? status,
    String? assignedTo,
    String? dueBefore,
    String? dueAfter,
    int page = 1,
    int limit = 20,
  }) =>
      _dataSource.getTasks(
        flatId,
        status: status,
        assignedTo: assignedTo,
        dueBefore: dueBefore,
        dueAfter: dueAfter,
        page: page,
        limit: limit,
      );

  @override
  Future<TaskEntity> getTask(String flatId, String taskId) =>
      _dataSource.getTask(flatId, taskId);

  @override
  Future<TaskEntity> createTask({
    required String flatId,
    required String title,
    String? description,
    String? assignedTo,
    String? dueDate,
    List<String>? subTaskTitles,
  }) =>
      _dataSource.createTask(
        flatId: flatId,
        title: title,
        description: description,
        assignedTo: assignedTo,
        dueDate: dueDate,
        subTaskTitles: subTaskTitles,
      );

  @override
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
  }) =>
      _dataSource.updateTask(
        flatId: flatId,
        taskId: taskId,
        title: title,
        description: description,
        assignedTo: assignedTo,
        dueDate: dueDate,
        clearAssignee: clearAssignee,
        clearDueDate: clearDueDate,
        status: status,
      );

  @override
  Future<void> deleteTask(String flatId, String taskId) =>
      _dataSource.deleteTask(flatId, taskId);

  @override
  Future<SubTaskEntity> addSubTask({
    required String flatId,
    required String taskId,
    required String title,
  }) =>
      _dataSource.addSubTask(flatId: flatId, taskId: taskId, title: title);

  @override
  Future<SubTaskEntity> updateSubTask({
    required String flatId,
    required String taskId,
    required String subTaskId,
    String? title,
    bool? isCompleted,
  }) =>
      _dataSource.updateSubTask(
        flatId: flatId,
        taskId: taskId,
        subTaskId: subTaskId,
        title: title,
        isCompleted: isCompleted,
      );

  @override
  Future<void> deleteSubTask({
    required String flatId,
    required String taskId,
    required String subTaskId,
  }) =>
      _dataSource.deleteSubTask(
        flatId: flatId,
        taskId: taskId,
        subTaskId: subTaskId,
      );
}
