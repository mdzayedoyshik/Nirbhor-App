import 'package:equatable/equatable.dart';

import '../../../domain/entities/flat_wallet_entity.dart';
import '../../../domain/entities/wallet_summary_entity.dart';

abstract class WalletState extends Equatable {
  const WalletState();
}

class WalletInitial extends WalletState {
  const WalletInitial();
  @override
  List<Object?> get props => [];
}

class WalletLoading extends WalletState {
  const WalletLoading();
  @override
  List<Object?> get props => [];
}

class WalletSummaryLoaded extends WalletState {
  const WalletSummaryLoaded(this.summary, {this.flatWallet});
  final WalletSummaryEntity summary;
  final FlatWalletEntity? flatWallet;
  @override
  List<Object?> get props => [summary, flatWallet];
}

class WalletActionLoading extends WalletState {
  const WalletActionLoading(this.summary, {this.flatWallet});
  final WalletSummaryEntity summary;
  final FlatWalletEntity? flatWallet;
  @override
  List<Object?> get props => [summary, flatWallet];
}

class WalletPaymentSubmitSuccess extends WalletState {
  const WalletPaymentSubmitSuccess(this.summary, {this.flatWallet});
  final WalletSummaryEntity summary;
  final FlatWalletEntity? flatWallet;
  @override
  List<Object?> get props => [summary, flatWallet];
}

class WalletError extends WalletState {
  const WalletError(this.message, {this.summary, this.flatWallet});
  final String message;
  final WalletSummaryEntity? summary;
  final FlatWalletEntity? flatWallet;
  @override
  List<Object?> get props => [message, summary, flatWallet];
}
