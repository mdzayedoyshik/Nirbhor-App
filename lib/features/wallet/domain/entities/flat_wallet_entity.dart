import 'package:equatable/equatable.dart';

class FlatWalletEntity extends Equatable {
  const FlatWalletEntity({
    required this.id,
    required this.flatId,
    required this.balance,
    required this.updatedAt,
  });

  final String id;
  final String flatId;
  final double balance;
  final String updatedAt;

  bool get isNegative => balance < 0;

  @override
  List<Object?> get props => [id, flatId, balance, updatedAt];
}
