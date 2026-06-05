import '../../domain/entities/wallet_member_summary_entity.dart';

class WalletMemberSummaryModel extends WalletMemberSummaryEntity {
  const WalletMemberSummaryModel({
    required super.flatMemberId,
    required super.memberName,
    super.photoUrl,
    required super.role,
    required super.balance,
  });

  factory WalletMemberSummaryModel.fromJson(Map<String, dynamic> json) =>
      WalletMemberSummaryModel(
        flatMemberId: json['flat_member_id'] as String,
        memberName: json['member_name'] as String,
        photoUrl: json['avatar_url'] as String?,
        role: json['role'] as String,
        balance: (json['balance'] as num).toDouble(),
      );
}
