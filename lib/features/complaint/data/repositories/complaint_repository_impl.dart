import '../../domain/entities/complaint_entity.dart';
import '../../domain/repositories/complaint_repository.dart';
import '../datasources/complaint_remote_datasource.dart';

class ComplaintRepositoryImpl implements ComplaintRepository {
  ComplaintRepositoryImpl({required ComplaintRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final ComplaintRemoteDataSource _dataSource;

  @override
  Future<Map<String, dynamic>> getComplaints(
    String flatId, {
    String? status,
    String? raisedBy,
    int page = 1,
    int limit = 20,
  }) =>
      _dataSource.getComplaints(
        flatId,
        status: status,
        raisedBy: raisedBy,
        page: page,
        limit: limit,
      );

  @override
  Future<ComplaintEntity> getComplaint(String flatId, String complaintId) =>
      _dataSource.getComplaint(flatId, complaintId);

  @override
  Future<ComplaintEntity> raiseComplaint({
    required String flatId,
    required String subject,
    String? description,
  }) =>
      _dataSource.raiseComplaint(
        flatId: flatId,
        subject: subject,
        description: description,
      );

  @override
  Future<ComplaintEntity> updateComplaintStatus({
    required String flatId,
    required String complaintId,
    required String status,
  }) =>
      _dataSource.updateComplaintStatus(
        flatId: flatId,
        complaintId: complaintId,
        status: status,
      );

  @override
  Future<ComplaintEntity> editComplaint({
    required String flatId,
    required String complaintId,
    String? subject,
    String? description,
  }) =>
      _dataSource.editComplaint(
        flatId: flatId,
        complaintId: complaintId,
        subject: subject,
        description: description,
      );

  @override
  Future<void> deleteComplaint(String flatId, String complaintId) =>
      _dataSource.deleteComplaint(flatId, complaintId);
}
