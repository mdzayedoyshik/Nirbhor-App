part of 'task_bloc.dart';

abstract class TaskState extends Equatable {
  const TaskState();
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {
  const TaskInitial();
}

class TaskListLoading extends TaskState {
  const TaskListLoading();
}

class TaskListLoaded extends TaskState {
  const TaskListLoaded({
    required this.tasks,
    required this.pagination,
    this.isLoadingMore = false,
  });
  final List<TaskEntity> tasks;
  final Map<String, dynamic> pagination;
  final bool isLoadingMore;

  bool get hasMore {
    final page = (pagination['page'] as int?) ?? 1;
    final limit = (pagination['limit'] as int?) ?? 20;
    final total = (pagination['total'] as int?) ?? 0;
    return page * limit < total;
  }

  TaskListLoaded copyWith({
    List<TaskEntity>? tasks,
    Map<String, dynamic>? pagination,
    bool? isLoadingMore,
  }) =>
      TaskListLoaded(
        tasks: tasks ?? this.tasks,
        pagination: pagination ?? this.pagination,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [tasks, pagination, isLoadingMore];
}

class TaskDetailLoading extends TaskState {
  const TaskDetailLoading();
}

class TaskDetailLoaded extends TaskState {
  const TaskDetailLoaded(this.task);
  final TaskEntity task;
  @override
  List<Object?> get props => [task];
}

class TaskActionLoading extends TaskState {
  const TaskActionLoading({this.detail});
  // Keep detail visible during sub-task mutations
  final TaskEntity? detail;
  @override
  List<Object?> get props => [detail];
}

class TaskActionSuccess extends TaskState {
  const TaskActionSuccess(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class TaskError extends TaskState {
  const TaskError(this.message, {this.detail});
  final String message;
  // Keep detail visible on error inside detail page
  final TaskEntity? detail;
  @override
  List<Object?> get props => [message, detail];
}
