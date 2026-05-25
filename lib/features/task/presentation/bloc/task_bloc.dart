import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/add_sub_task_usecase.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/delete_sub_task_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';
import '../../domain/usecases/get_task_usecase.dart';
import '../../domain/usecases/get_tasks_usecase.dart';
import '../../domain/usecases/update_sub_task_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc({
    required GetTasksUseCase getTasks,
    required GetTaskUseCase getTask,
    required CreateTaskUseCase createTask,
    required UpdateTaskUseCase updateTask,
    required DeleteTaskUseCase deleteTask,
    required AddSubTaskUseCase addSubTask,
    required UpdateSubTaskUseCase updateSubTask,
    required DeleteSubTaskUseCase deleteSubTask,
  })  : _getTasks = getTasks,
        _getTask = getTask,
        _createTask = createTask,
        _updateTask = updateTask,
        _deleteTask = deleteTask,
        _addSubTask = addSubTask,
        _updateSubTask = updateSubTask,
        _deleteSubTask = deleteSubTask,
        super(const TaskInitial()) {
    on<TasksLoadRequested>(_onLoad);
    on<TasksLoadMoreRequested>(_onLoadMore);
    on<TaskDetailRequested>(_onDetail);
    on<TaskCreateRequested>(_onCreate);
    on<TaskUpdateRequested>(_onUpdate);
    on<TaskDeleteRequested>(_onDelete);
    on<SubTaskAddRequested>(_onSubTaskAdd);
    on<SubTaskUpdateRequested>(_onSubTaskUpdate);
    on<SubTaskDeleteRequested>(_onSubTaskDelete);
  }

  final GetTasksUseCase _getTasks;
  final GetTaskUseCase _getTask;
  final CreateTaskUseCase _createTask;
  final UpdateTaskUseCase _updateTask;
  final DeleteTaskUseCase _deleteTask;
  final AddSubTaskUseCase _addSubTask;
  final UpdateSubTaskUseCase _updateSubTask;
  final DeleteSubTaskUseCase _deleteSubTask;

  Future<void> _onLoad(TasksLoadRequested event, Emitter<TaskState> emit) async {
    emit(const TaskListLoading());
    try {
      final result = await _getTasks(
        event.flatId,
        status: event.status,
        assignedTo: event.assignedTo,
      );
      emit(TaskListLoaded(
        tasks: List<TaskEntity>.from(result['tasks'] as List),
        pagination: result['pagination'] as Map<String, dynamic>,
      ));
    } catch (e) {
      emit(TaskError(_msg(e)));
    }
  }

  Future<void> _onLoadMore(TasksLoadMoreRequested event, Emitter<TaskState> emit) async {
    final current = state;
    if (current is! TaskListLoaded || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final result = await _getTasks(
        event.flatId,
        status: event.status,
        assignedTo: event.assignedTo,
        page: event.nextPage,
      );
      final newTasks = List<TaskEntity>.from(result['tasks'] as List);
      emit(TaskListLoaded(
        tasks: [...current.tasks, ...newTasks],
        pagination: result['pagination'] as Map<String, dynamic>,
      ));
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onDetail(TaskDetailRequested event, Emitter<TaskState> emit) async {
    emit(const TaskDetailLoading());
    try {
      final task = await _getTask(event.flatId, event.taskId);
      emit(TaskDetailLoaded(task));
    } catch (e) {
      emit(TaskError(_msg(e)));
    }
  }

  Future<void> _onCreate(TaskCreateRequested event, Emitter<TaskState> emit) async {
    emit(const TaskActionLoading());
    try {
      await _createTask(
        flatId: event.flatId,
        title: event.title,
        description: event.description,
        assignedTo: event.assignedTo,
        dueDate: event.dueDate,
        subTaskTitles: event.subTaskTitles,
      );
      emit(const TaskActionSuccess('Task created'));
    } catch (e) {
      emit(TaskError(_msg(e)));
    }
  }

  Future<void> _onUpdate(TaskUpdateRequested event, Emitter<TaskState> emit) async {
    final prevDetail = state is TaskDetailLoaded ? (state as TaskDetailLoaded).task : null;
    emit(TaskActionLoading(detail: prevDetail));
    try {
      final updated = await _updateTask(
        flatId: event.flatId,
        taskId: event.taskId,
        title: event.title,
        description: event.description,
        assignedTo: event.assignedTo,
        dueDate: event.dueDate,
        clearAssignee: event.clearAssignee,
        clearDueDate: event.clearDueDate,
        status: event.status,
      );
      emit(const TaskActionSuccess('Task updated'));
      emit(TaskDetailLoaded(updated));
    } catch (e) {
      emit(TaskError(_msg(e), detail: prevDetail));
      if (prevDetail != null) emit(TaskDetailLoaded(prevDetail));
    }
  }

  Future<void> _onDelete(TaskDeleteRequested event, Emitter<TaskState> emit) async {
    emit(const TaskActionLoading());
    try {
      await _deleteTask(event.flatId, event.taskId);
      emit(const TaskActionSuccess('Task deleted'));
    } catch (e) {
      emit(TaskError(_msg(e)));
    }
  }

  Future<void> _onSubTaskAdd(SubTaskAddRequested event, Emitter<TaskState> emit) async {
    final prevDetail = state is TaskDetailLoaded ? (state as TaskDetailLoaded).task : null;
    emit(TaskActionLoading(detail: prevDetail));
    try {
      await _addSubTask(flatId: event.flatId, taskId: event.taskId, title: event.title);
      // Reload detail to get fresh sub-tasks list
      final updated = await _getTask(event.flatId, event.taskId);
      emit(const TaskActionSuccess('Sub-task added'));
      emit(TaskDetailLoaded(updated));
    } catch (e) {
      emit(TaskError(_msg(e), detail: prevDetail));
      if (prevDetail != null) emit(TaskDetailLoaded(prevDetail));
    }
  }

  Future<void> _onSubTaskUpdate(SubTaskUpdateRequested event, Emitter<TaskState> emit) async {
    final prevDetail = state is TaskDetailLoaded ? (state as TaskDetailLoaded).task : null;
    emit(TaskActionLoading(detail: prevDetail));
    try {
      await _updateSubTask(
        flatId: event.flatId,
        taskId: event.taskId,
        subTaskId: event.subTaskId,
        title: event.title,
        isCompleted: event.isCompleted,
      );
      // Reload detail to get consistent state
      final updated = await _getTask(event.flatId, event.taskId);
      emit(TaskDetailLoaded(updated));
    } catch (e) {
      emit(TaskError(_msg(e), detail: prevDetail));
      if (prevDetail != null) emit(TaskDetailLoaded(prevDetail));
    }
  }

  Future<void> _onSubTaskDelete(SubTaskDeleteRequested event, Emitter<TaskState> emit) async {
    final prevDetail = state is TaskDetailLoaded ? (state as TaskDetailLoaded).task : null;
    emit(TaskActionLoading(detail: prevDetail));
    try {
      await _deleteSubTask(
        flatId: event.flatId,
        taskId: event.taskId,
        subTaskId: event.subTaskId,
      );
      final updated = await _getTask(event.flatId, event.taskId);
      emit(const TaskActionSuccess('Sub-task deleted'));
      emit(TaskDetailLoaded(updated));
    } catch (e) {
      emit(TaskError(_msg(e), detail: prevDetail));
      if (prevDetail != null) emit(TaskDetailLoaded(prevDetail));
    }
  }

  String _msg(Object e) {
    final s = e.toString();
    if (s.contains('ServerException')) {
      final match = RegExp(r'message: (.+?)\)').firstMatch(s);
      return match?.group(1) ?? 'Something went wrong';
    }
    return 'Something went wrong';
  }
}
