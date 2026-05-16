import '../../domain/entities/flat_preview_entity.dart';

class FlatPreviewModel extends FlatPreviewEntity {
  const FlatPreviewModel({
    required super.flatId,
    required super.flatName,
    super.photoUrl,
    super.address,
    required super.memberCount,
    required super.myStatus,
    required super.joinCode,
  });

  factory FlatPreviewModel.fromJson(
    Map<String, dynamic> json, {
    required String joinCode,
  }) =>
      FlatPreviewModel(
        flatId: json['flat_id'] as String,
        flatName: json['flat_name'] as String,
        photoUrl: json['photo_url'] as String?,
        address: json['address'] as String?,
        memberCount: json['member_count'] as int,
        myStatus: json['my_status'] as String,
        joinCode: joinCode,
      );
}
