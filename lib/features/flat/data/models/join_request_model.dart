import '../../domain/entities/join_request_entity.dart';

class JoinRequestModel extends JoinRequestEntity {
  const JoinRequestModel({
    required super.requestId,
    required super.flatId,
    super.flatName,
    super.userId,
    super.userName,
    super.userEmail,
    required super.status,
    required super.requestedAt,
  });

  factory JoinRequestModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackFlatId,
  }) => JoinRequestModel(
        requestId: (json['request_id'] ?? json['id']) as String,
        flatId: (json['flat_id'] as String?) ?? fallbackFlatId ?? '',
        flatName: json['flat_name'] as String?,
        userId: json['user_id'] as String?,
        userName: json['user_name'] as String?,
        userEmail: json['user_email'] as String?,
        status: json['status'] as String,
        requestedAt: json['requested_at'] as String,
      );
}
