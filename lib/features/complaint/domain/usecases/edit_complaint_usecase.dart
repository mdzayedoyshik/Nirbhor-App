import '../entities/complaint_entity.dart';
import '../repositories/complaint_repository.dart';

class EditComplaintUseCase {
  EditComplaintUseCase(this._repo);
  final ComplaintRepository _repo;

  Future<ComplaintEntity> call({
    required String flatId,
    required String complaintId,
    String? subject,
    String? description,
  }) =>
      _repo.editComplaint(
        flatId: flatId,
        complaintId: complaintId,
        subject: subject,
        description: description,
      );
}
