import '../../domain/entities/fixed_expense_entity.dart';
import '../../domain/entities/flat_entity.dart';
import '../../domain/entities/flat_preview_entity.dart';
import '../../domain/entities/join_request_entity.dart';
import '../../domain/repositories/flat_repository.dart';
import '../datasources/flat_remote_datasource.dart';
import '../models/fixed_expense_model.dart';
import '../models/flat_model.dart';
import '../models/flat_preview_model.dart';
import '../models/join_request_model.dart';

class FlatRepositoryImpl implements FlatRepository {
  final FlatRemoteDataSource _dataSource;

  FlatRepositoryImpl({required FlatRemoteDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<FlatEntity> getMyFlat() async {
    final response = await _dataSource.getMyFlat();
    final data = response['data'] as Map<String, dynamic>;
    return FlatModel.fromJson(data['flat'] as Map<String, dynamic>);
  }

  @override
  Future<FlatEntity> createFlat({
    required String name,
    String? address,
    String? photoUrl,
  }) async {
    final response = await _dataSource.createFlat(
      name: name,
      address: address,
      photoUrl: photoUrl,
    );
    final data = response['data'] as Map<String, dynamic>;
    // Create returns partial flat — fetch full to get members/expenses
    final flatId = data['id'] as String;
    return getFlat(flatId);
  }

  @override
  Future<FlatEntity> getFlat(String flatId) async {
    final response = await _dataSource.getFlat(flatId);
    return FlatModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<FlatEntity> updateFlat({
    required String flatId,
    String? name,
    String? address,
    String? photoUrl,
  }) async {
    final response = await _dataSource.updateFlat(
      flatId: flatId,
      name: name,
      address: address,
      photoUrl: photoUrl,
    );
    return FlatModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteFlat(String flatId) async {
    await _dataSource.deleteFlat(flatId);
  }

  @override
  Future<FlatPreviewEntity> previewFlat(String code) async {
    final response = await _dataSource.previewFlat(code);
    return FlatPreviewModel.fromJson(
      response['data'] as Map<String, dynamic>,
      joinCode: code,
    );
  }

  @override
  Future<JoinRequestEntity> sendJoinRequest(String joinCode) async {
    final response = await _dataSource.sendJoinRequest(joinCode);
    return JoinRequestModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<JoinRequestEntity>> getMyRequests() async {
    final response = await _dataSource.getMyRequests();
    final data = response['data'] as Map<String, dynamic>;
    final list = data['requests'] as List<dynamic>;
    return list
        .map((e) => JoinRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cancelJoinRequest(String requestId) async {
    await _dataSource.cancelJoinRequest(requestId);
  }

  @override
  Future<List<JoinRequestEntity>> getJoinRequests(String flatId) async {
    final response = await _dataSource.getJoinRequests(flatId);
    final data = response['data'] as Map<String, dynamic>;
    final list = data['requests'] as List<dynamic>;
    return list
        .map(
          (e) => JoinRequestModel.fromJson(
            e as Map<String, dynamic>,
            fallbackFlatId: flatId,
          ),
        )
        .toList();
  }

  @override
  Future<void> approveJoinRequest({
    required String flatId,
    required String requestId,
    required double fixedContribution,
  }) async {
    await _dataSource.approveJoinRequest(
      flatId: flatId,
      requestId: requestId,
      fixedContribution: fixedContribution,
    );
  }

  @override
  Future<void> declineJoinRequest({
    required String flatId,
    required String requestId,
  }) async {
    await _dataSource.declineJoinRequest(flatId: flatId, requestId: requestId);
  }

  @override
  Future<List<FixedExpenseEntity>> getFixedExpenses(String flatId) async {
    final response = await _dataSource.getFixedExpenses(flatId);
    final data = response['data'] as Map<String, dynamic>;
    final list = data['expenses'] as List<dynamic>;
    return list
        .map((e) => FixedExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FixedExpenseEntity> addFixedExpense({
    required String flatId,
    required String expenseType,
    required double amount,
  }) async {
    final response = await _dataSource.addFixedExpense(
      flatId: flatId,
      expenseType: expenseType,
      amount: amount,
    );
    return FixedExpenseModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<FixedExpenseEntity> updateFixedExpense({
    required String flatId,
    required String expenseId,
    String? expenseType,
    double? amount,
  }) async {
    final response = await _dataSource.updateFixedExpense(
      flatId: flatId,
      expenseId: expenseId,
      expenseType: expenseType,
      amount: amount,
    );
    return FixedExpenseModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteFixedExpense({
    required String flatId,
    required String expenseId,
  }) async {
    await _dataSource.deleteFixedExpense(flatId: flatId, expenseId: expenseId);
  }

  @override
  Future<void> redistribute(String flatId) async {
    await _dataSource.redistribute(flatId);
  }
}
