import 'package:equatable/equatable.dart';

import '../../../domain/entities/wallet_member_summary_entity.dart';

abstract class AllWalletsState extends Equatable {
  const AllWalletsState();
}

class AllWalletsInitial extends AllWalletsState {
  const AllWalletsInitial();
  @override
  List<Object?> get props => [];
}

class AllWalletsLoading extends AllWalletsState {
  const AllWalletsLoading();
  @override
  List<Object?> get props => [];
}

class AllWalletsLoaded extends AllWalletsState {
  const AllWalletsLoaded(this.wallets);
  final List<WalletMemberSummaryEntity> wallets;
  @override
  List<Object?> get props => [wallets];
}

class AllWalletsError extends AllWalletsState {
  const AllWalletsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
