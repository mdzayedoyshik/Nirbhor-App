import '../entities/complaint_entity.dart';
import '../repositories/complaint_repository.dart';

class UpdateComplaintStatusUseCase {
  UpdateComplaintStatusUseCase(this._repo);
  final ComplaintRepository _repo;

  Future<ComplaintEntity> call({
    required String flatId,
    required String complaintId,
    required String status,
  }) =>
      _repo.updateComplaintStatus(
        flatId: flatId,
        complaintId: complaintId,
        status: status,
      );
}
