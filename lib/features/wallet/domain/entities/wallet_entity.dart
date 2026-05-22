import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  const WalletEntity({
    required this.id,
    required this.flatMemberId,
    required this.balance,
    required this.updatedAt,
  });

  final String id;
  final String flatMemberId;
  final double balance;
  final String updatedAt;

  bool get isNegative => balance < 0;

  @override
  List<Object?> get props => [id, flatMemberId, balance, updatedAt];
}
