import '../../domain/entities/flat_wallet_entity.dart';

class FlatWalletModel extends FlatWalletEntity {
  const FlatWalletModel({
    required super.id,
    required super.flatId,
    required super.balance,
    required super.updatedAt,
  });

  factory FlatWalletModel.fromJson(Map<String, dynamic> json) =>
      FlatWalletModel(
        id: json['id'] as String,
        flatId: json['flat_id'] as String,
        balance: (json['balance'] as num).toDouble(),
        updatedAt: json['updated_at'] as String,
      );
}
