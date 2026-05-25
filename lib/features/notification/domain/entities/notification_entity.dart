import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.isRead,
    required this.createdAt,
    this.flatId,
    this.message,
    this.referenceId,
  });

  final String id;
  final String? flatId;
  final String type;
  final String title;
  final String? message;
  final bool isRead;
  final String? referenceId;
  final String createdAt;

  @override
  List<Object?> get props => [
        id,
        flatId,
        type,
        title,
        message,
        isRead,
        referenceId,
        createdAt,
      ];
}
