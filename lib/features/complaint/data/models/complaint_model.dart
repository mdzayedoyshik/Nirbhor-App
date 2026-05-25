import '../../domain/entities/complaint_entity.dart';

class ComplaintModel extends ComplaintEntity {
  const ComplaintModel({
    required super.id,
    required super.flatId,
    required super.raisedBy,
    required super.raisedByName,
    required super.subject,
    required super.status,
    required super.createdAt,
    super.description,
    super.resolvedAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] as String,
      flatId: json['flat_id'] as String,
      raisedBy: json['raised_by'] as String,
      raisedByName: json['raised_by_name'] as String? ?? '',
      subject: json['subject'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String? ?? '',
      description: json['description'] as String?,
      resolvedAt: json['resolved_at'] as String?,
    );
  }
}
