part of 'task_bloc.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object?> get props => [];
}

class TasksLoadRequested extends TaskEvent {
  const TasksLoadRequested(this.flatId, {this.status, this.assignedTo});
  final String flatId;
  final String? status;
  final String? assignedTo;
  @override
  List<Object?> get props => [flatId, status, assignedTo];
}

class TasksLoadMoreRequested extends TaskEvent {
  const TasksLoadMoreRequested(this.flatId, {this.status, this.assignedTo, required this.nextPage});
  final String flatId;
  final String? status;
  final String? assignedTo;
  final int nextPage;
  @override
  List<Object?> get props => [flatId, status, assignedTo, nextPage];
}

class TaskDetailRequested extends TaskEvent {
  const TaskDetailRequested(this.flatId, this.taskId);
  final String flatId;
  final String taskId;
  @override
  List<Object?> get props => [flatId, taskId];
}

class TaskCreateRequested extends TaskEvent {
  const TaskCreateRequested({
    required this.flatId,
    required this.title,
    this.description,
    this.assignedTo,
    this.dueDate,
    this.subTaskTitles,
  });
  final String flatId;
  final String title;
  final String? description;
  final String? assignedTo;
  final String? dueDate;
  final List<String>? subTaskTitles;
  @override
  List<Object?> get props => [flatId, title, description, assignedTo, dueDate, subTaskTitles];
}

class TaskUpdateRequested extends TaskEvent {
  const TaskUpdateRequested({
    required this.flatId,
    required this.taskId,
    this.title,
    this.description,
    this.assignedTo,
    this.dueDate,
    this.clearAssignee = false,
    this.clearDueDate = false,
    this.status,
  });
  final String flatId;
  final String taskId;
  final String? title;
  final String? description;
  final String? assignedTo;
  final String? dueDate;
  final bool clearAssignee;
  final bool clearDueDate;
  final String? status;
  @override
  List<Object?> get props => [flatId, taskId, title, description, assignedTo, dueDate, clearAssignee, clearDueDate, status];
}

class TaskDeleteRequested extends TaskEvent {
  const TaskDeleteRequested(this.flatId, this.taskId);
  final String flatId;
  final String taskId;
  @override
  List<Object?> get props => [flatId, taskId];
}

class SubTaskAddRequested extends TaskEvent {
  const SubTaskAddRequested({required this.flatId, required this.taskId, required this.title});
  final String flatId;
  final String taskId;
  final String title;
  @override
  List<Object?> get props => [flatId, taskId, title];
}

class SubTaskUpdateRequested extends TaskEvent {
  const SubTaskUpdateRequested({
    required this.flatId,
    required this.taskId,
    required this.subTaskId,
    this.title,
    this.isCompleted,
  });
  final String flatId;
  final String taskId;
  final String subTaskId;
  final String? title;
  final bool? isCompleted;
  @override
  List<Object?> get props => [flatId, taskId, subTaskId, title, isCompleted];
}

class SubTaskDeleteRequested extends TaskEvent {
  const SubTaskDeleteRequested({required this.flatId, required this.taskId, required this.subTaskId});
  final String flatId;
  final String taskId;
  final String subTaskId;
  @override
  List<Object?> get props => [flatId, taskId, subTaskId];
}
