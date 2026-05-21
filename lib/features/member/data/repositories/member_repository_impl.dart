import '../../../flat/data/models/flat_member_model.dart';
import '../../../flat/domain/entities/flat_member_entity.dart';
import '../../domain/entities/finalize_exit_entity.dart';
import '../../domain/entities/settlement_entity.dart';
import '../../domain/repositories/member_repository.dart';
import '../datasources/member_remote_datasource.dart';
import '../models/finalize_exit_model.dart';
import '../models/settlement_model.dart';

class MemberRepositoryImpl implements MemberRepository {
  final MemberRemoteDataSource _dataSource;

  MemberRepositoryImpl({required MemberRemoteDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<List<FlatMemberEntity>> getMembers(String flatId) async {
    final response = await _dataSource.getMembers(flatId);
    final data = response['data'] as Map<String, dynamic>;
    final list = data['members'] as List<dynamic>;
    return list
        .map((e) => FlatMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> changeRole({
    required String flatId,
    required String memberId,
    required String role,
  }) async {
    await _dataSource.changeRole(
      flatId: flatId,
      memberId: memberId,
      role: role,
    );
  }

  @override
  Future<void> transferManager({
    required String flatId,
    required String newManagerId,
  }) async {
    await _dataSource.transferManager(
      flatId: flatId,
      newManagerId: newManagerId,
    );
  }

  @override
  Future<SettlementEntity> initiateExit({
    required String flatId,
    required String memberId,
    double fixedRefund = 0,
  }) async {
    final response = await _dataSource.initiateExit(
      flatId: flatId,
      memberId: memberId,
      fixedRefund: fixedRefund,
    );
    final data = response['data'] as Map<String, dynamic>;
    return SettlementModel.fromJson(data['settlement'] as Map<String, dynamic>);
  }

  @override
  Future<SettlementEntity> getSettlement({
    required String flatId,
    required String memberId,
  }) async {
    final response = await _dataSource.getSettlement(
      flatId: flatId,
      memberId: memberId,
    );
    final data = response['data'] as Map<String, dynamic>;
    return SettlementModel.fromJson(data['settlement'] as Map<String, dynamic>);
  }

  @override
  Future<FinalizeExitEntity> finalizeExit({
    required String flatId,
    required String memberId,
  }) async {
    final response = await _dataSource.finalizeExit(
      flatId: flatId,
      memberId: memberId,
    );
    return FinalizeExitModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> cancelExit({
    required String flatId,
    required String memberId,
  }) async {
    await _dataSource.cancelExit(flatId: flatId, memberId: memberId);
  }
}
