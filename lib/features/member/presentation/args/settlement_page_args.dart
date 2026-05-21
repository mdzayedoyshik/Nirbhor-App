import '../../domain/entities/settlement_entity.dart';

class SettlementPageArgs {
  final String flatId;
  final String memberId;
  final SettlementEntity settlement;
  final bool isManager;

  const SettlementPageArgs({
    required this.flatId,
    required this.memberId,
    required this.settlement,
    required this.isManager,
  });
}
