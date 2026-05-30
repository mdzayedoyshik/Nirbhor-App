import '../entities/complaint_entity.dart';
import '../repositories/complaint_repository.dart';

class RaiseComplaintUseCase {
  RaiseComplaintUseCase(this._repo);
  final ComplaintRepository _repo;

  Future<ComplaintEntity> call({
    required String flatId,
    required String subject,
    String? description,
  }) =>
      _repo.raiseComplaint(
        flatId: flatId,
        subject: subject,
        description: description,
      );
}
