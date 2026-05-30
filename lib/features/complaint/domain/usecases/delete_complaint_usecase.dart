import '../repositories/complaint_repository.dart';

class DeleteComplaintUseCase {
  DeleteComplaintUseCase(this._repo);
  final ComplaintRepository _repo;

  Future<void> call(String flatId, String complaintId) =>
      _repo.deleteComplaint(flatId, complaintId);
}
