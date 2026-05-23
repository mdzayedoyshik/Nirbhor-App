import 'package:equatable/equatable.dart';

import 'settlement_entity.dart';

class ExitStatusEntity extends Equatable {
  final String status; // 'none' | 'pending' | 'awaiting_acknowledgment'
  final String? flatId;
  final String? flatName;
  final SettlementEntity? settlement;

  const ExitStatusEntity({
    required this.status,
    this.flatId,
    this.flatName,
    this.settlement,
  });

  bool get isNone => status == 'none';
  bool get isPending => status == 'pending';
  bool get isAwaitingAck => status == 'awaiting_acknowledgment';

  @override
  List<Object?> get props => [status, flatId, flatName, settlement];
}
