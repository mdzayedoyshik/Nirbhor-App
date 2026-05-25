import '../../../flat/domain/entities/flat_member_entity.dart';
import '../../domain/entities/task_entity.dart';

class TaskPageArgs {
  const TaskPageArgs({
    required this.flatId,
    required this.canManage,
    required this.myMemberId,
    required this.members,
  });

  final String flatId;
  final bool canManage;
  final String myMemberId;
  final List<FlatMemberEntity> members;
}

class TaskDetailArgs {
  const TaskDetailArgs({
    required this.flatId,
    required this.task,
    required this.canManage,
    required this.myMemberId,
    required this.members,
  });

  final String flatId;
  final TaskEntity task;
  final bool canManage;
  final String myMemberId;
  final List<FlatMemberEntity> members;
}
