import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.isRead,
    required super.createdAt,
    super.flatId,
    super.message,
    super.referenceId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      flatId: json['flat_id'] as String?,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      referenceId: json['reference_id'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
