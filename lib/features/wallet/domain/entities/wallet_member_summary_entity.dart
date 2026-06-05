import 'package:equatable/equatable.dart';

class WalletMemberSummaryEntity extends Equatable {
  const WalletMemberSummaryEntity({
    required this.flatMemberId,
    required this.memberName,
    this.photoUrl,
    required this.role,
    required this.balance,
  });

  final String flatMemberId;
  final String memberName;
  final String? photoUrl;
  final String role;
  final double balance;

  bool get isNegative => balance < 0;

  @override
  List<Object?> get props => [flatMemberId, memberName, photoUrl, role, balance];
}
