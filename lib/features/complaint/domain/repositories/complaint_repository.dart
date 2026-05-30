import '../entities/complaint_entity.dart';

abstract class ComplaintRepository {
  Future<Map<String, dynamic>> getComplaints(
    String flatId, {
    String? status,
    String? raisedBy,
    int page = 1,
    int limit = 20,
  });

  Future<ComplaintEntity> getComplaint(String flatId, String complaintId);

  Future<ComplaintEntity> raiseComplaint({
    required String flatId,
    required String subject,
    String? description,
  });

  Future<ComplaintEntity> updateComplaintStatus({
    required String flatId,
    required String complaintId,
    required String status,
  });

  Future<ComplaintEntity> editComplaint({
    required String flatId,
    required String complaintId,
    String? subject,
    String? description,
  });

  Future<void> deleteComplaint(String flatId, String complaintId);
}
