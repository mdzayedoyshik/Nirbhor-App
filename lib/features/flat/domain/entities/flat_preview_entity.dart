import 'package:equatable/equatable.dart';

class FlatPreviewEntity extends Equatable {
  final String flatId;
  final String flatName;
  final String? address;
  final int memberCount;
  final String myStatus; // 'not_member' | 'pending' | 'active_member'
  final String joinCode;

  const FlatPreviewEntity({
    required this.flatId,
    required this.flatName,
    this.address,
    required this.memberCount,
    required this.myStatus,
    required this.joinCode,
  });

  bool get isNotMember => myStatus == 'not_member';
  bool get isPending => myStatus == 'pending';
  bool get isActiveMember => myStatus == 'active_member';

  @override
  List<Object?> get props => [
    flatId,
    flatName,
    address,
    memberCount,
    myStatus,
    joinCode,
  ];
}
