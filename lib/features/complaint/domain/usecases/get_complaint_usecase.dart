import '../entities/complaint_entity.dart';
import '../repositories/complaint_repository.dart';

class GetComplaintUseCase {
  GetComplaintUseCase(this._repo);
  final ComplaintRepository _repo;

  Future<ComplaintEntity> call(String flatId, String complaintId) =>
      _repo.getComplaint(flatId, complaintId);
}
