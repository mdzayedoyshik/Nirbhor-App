import 'package:equatable/equatable.dart';

class JoinRequestEntity extends Equatable {
  final String requestId;
  final String flatId;
  final String? flatName;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String status; // 'pending' | 'approved' | 'declined' | 'cancelled'
  final String requestedAt;

  const JoinRequestEntity({
    required this.requestId,
    required this.flatId,
    this.flatName,
    this.userId,
    this.userName,
    this.userEmail,
    required this.status,
    required this.requestedAt,
  });

  bool get isPending => status == 'pending';

  @override
  List<Object?> get props => [
    requestId,
    flatId,
    flatName,
    userId,
    userName,
    userEmail,
    status,
    requestedAt,
  ];
}
