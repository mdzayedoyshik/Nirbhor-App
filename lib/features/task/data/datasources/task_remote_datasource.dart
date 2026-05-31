import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/sub_task_model.dart';
import '../models/task_model.dart';

class TaskRemoteDataSource {
  TaskRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getTasks(
    String flatId, {
    String? status,
    String? assignedTo,
    String? dueBefore,
    String? dueAfter,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      'status': ?status,
      'assigned_to': ?assignedTo,
      'due_before': ?dueBefore,
      'due_after': ?dueAfter,
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final endpoint = '${ApiEndpoints.flatTasks(flatId)}?$query';
    final response = await _apiClient.get(endpoint, auth: true);
    final data = response['data'] as Map<String, dynamic>;
    return {
      'tasks': (data['tasks'] as List)
          .map((t) => TaskModel.fromJson(t as Map<String, dynamic>))
          .toList(),
      'pagination': data['pagination'] as Map<String, dynamic>,
    };
  }

  Future<TaskModel> getTask(String flatId, String taskId) async {
    final response = await _apiClient.get(
      ApiEndpoints.flatTask(flatId, taskId),
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return TaskModel.fromJson(data['task'] as Map<String, dynamic>);
  }

  Future<TaskModel> createTask({
    required String flatId,
    required String title,
    String? description,
    String? assignedTo,
    List<String>? assignedToIds,
    String? dueDate,
    List<String>? subTaskTitles,
  }) async {
    final effectiveIds = assignedToIds?.isNotEmpty == true
        ? assignedToIds!
        : assignedTo != null
            ? [assignedTo]
            : null;
    final body = <String, dynamic>{
      'title': title,
      'description': ?description,
      'assigned_to_ids': ?effectiveIds,
      'due_date': ?dueDate,
      if (subTaskTitles != null && subTaskTitles.isNotEmpty)
        'sub_tasks': subTaskTitles.map((t) => {'title': t}).toList(),
    };
    final response = await _apiClient.post(
      ApiEndpoints.flatTasks(flatId),
      body,
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return TaskModel.fromJson(data['task'] as Map<String, dynamic>);
  }

  Future<TaskModel> updateTask({
    required String flatId,
    required String taskId,
    String? title,
    String? description,
    String? assignedTo,
    List<String>? assignedToIds,
    bool clearAssignee = false,
    String? dueDate,
    bool clearDueDate = false,
    String? status,
  }) async {
    final body = <String, dynamic>{
      'title': ?title,
      'description': ?description,
      if (clearAssignee)
        'assigned_to_ids': <String>[]
      else if (assignedToIds != null)
        'assigned_to_ids': assignedToIds
      else if (assignedTo != null)
        'assigned_to_ids': [assignedTo],
      if (clearDueDate) 'due_date': null
      else 'due_date': ?dueDate,
      'status': ?status,
    };
    final response = await _apiClient.put(
      ApiEndpoints.flatTask(flatId, taskId),
      body,
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return TaskModel.fromJson(data['task'] as Map<String, dynamic>);
  }

  Future<void> deleteTask(String flatId, String taskId) =>
      _apiClient.delete(ApiEndpoints.flatTask(flatId, taskId), auth: true);

  Future<SubTaskModel> addSubTask({
    required String flatId,
    required String taskId,
    required String title,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.flatSubTasks(flatId, taskId),
      {'title': title},
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return SubTaskModel.fromJson(data['sub_task'] as Map<String, dynamic>);
  }

  Future<SubTaskModel> updateSubTask({
    required String flatId,
    required String taskId,
    required String subTaskId,
    String? title,
    bool? isCompleted,
  }) async {
    final body = <String, dynamic>{
      'title': ?title,
      'is_completed': ?isCompleted,
    };
    final response = await _apiClient.patch(
      ApiEndpoints.flatSubTask(flatId, taskId, subTaskId),
      body,
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return SubTaskModel.fromJson(data['sub_task'] as Map<String, dynamic>);
  }

  Future<void> deleteSubTask({
    required String flatId,
    required String taskId,
    required String subTaskId,
  }) =>
      _apiClient.delete(
        ApiEndpoints.flatSubTask(flatId, taskId, subTaskId),
        auth: true,
      );
}
