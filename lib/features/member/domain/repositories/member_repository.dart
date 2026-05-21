import '../../../flat/domain/entities/flat_member_entity.dart';
import '../entities/finalize_exit_entity.dart';
import '../entities/settlement_entity.dart';

abstract class MemberRepository {
  Future<List<FlatMemberEntity>> getMembers(String flatId);

  Future<void> changeRole({
    required String flatId,
    required String memberId,
    required String role,
  });

  Future<void> transferManager({
    required String flatId,
    required String newManagerId,
  });

  Future<SettlementEntity> initiateExit({
    required String flatId,
    required String memberId,
    double fixedRefund = 0,
  });

  Future<SettlementEntity> getSettlement({
    required String flatId,
    required String memberId,
  });

  Future<FinalizeExitEntity> finalizeExit({
    required String flatId,
    required String memberId,
  });

  Future<void> cancelExit({
    required String flatId,
    required String memberId,
  });
}
