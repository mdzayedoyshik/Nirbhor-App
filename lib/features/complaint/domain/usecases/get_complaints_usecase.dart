import '../repositories/complaint_repository.dart';

class GetComplaintsUseCase {
  GetComplaintsUseCase(this._repo);
  final ComplaintRepository _repo;

  Future<Map<String, dynamic>> call(
    String flatId, {
    String? status,
    String? raisedBy,
    int page = 1,
    int limit = 20,
  }) =>
      _repo.getComplaints(
        flatId,
        status: status,
        raisedBy: raisedBy,
        page: page,
        limit: limit,
      );
}
