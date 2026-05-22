import '../../domain/entities/wallet_entity.dart';

class WalletModel extends WalletEntity {
  const WalletModel({
    required super.id,
    required super.flatMemberId,
    required super.balance,
    required super.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        id: json['id'] as String,
        flatMemberId: json['flat_member_id'] as String,
        balance: (json['balance'] as num).toDouble(),
        updatedAt: json['updated_at'] as String,
      );
}
