import '../entities/fixed_expense_entity.dart';
import '../entities/flat_entity.dart';
import '../entities/flat_preview_entity.dart';
import '../entities/join_request_entity.dart';

abstract class FlatRepository {
  Future<FlatEntity> getMyFlat();

  Future<FlatEntity> createFlat({
    required String name,
    String? address,
    String? timezone,
  });

  Future<FlatEntity> getFlat(String flatId);

  Future<FlatEntity> updateFlat({
    required String flatId,
    String? name,
    String? address,
    String? timezone,
  });

  Future<void> deleteFlat(String flatId);

  Future<FlatPreviewEntity> previewFlat(String code);

  Future<JoinRequestEntity> sendJoinRequest(String joinCode);

  Future<List<JoinRequestEntity>> getMyRequests();

  Future<void> cancelJoinRequest(String requestId);

  Future<List<JoinRequestEntity>> getJoinRequests(String flatId);

  Future<void> approveJoinRequest({
    required String flatId,
    required String requestId,
    required double fixedContribution,
  });

  Future<void> declineJoinRequest({
    required String flatId,
    required String requestId,
  });

  Future<List<FixedExpenseEntity>> getFixedExpenses(String flatId);

  Future<FixedExpenseEntity> addFixedExpense({
    required String flatId,
    required String expenseType,
    required double amount,
  });

  Future<FixedExpenseEntity> updateFixedExpense({
    required String flatId,
    required String expenseId,
    String? expenseType,
    double? amount,
  });

  Future<void> deleteFixedExpense({
    required String flatId,
    required String expenseId,
  });

  Future<void> redistribute(
    String flatId, {
    List<dynamic>? contributions,
  });
}
