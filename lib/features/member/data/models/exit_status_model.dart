import '../../domain/entities/exit_status_entity.dart';
import 'settlement_model.dart';

class ExitStatusModel extends ExitStatusEntity {
  const ExitStatusModel({
    required super.status,
    super.flatId,
    super.flatName,
    super.settlement,
  });

  factory ExitStatusModel.fromJson(Map<String, dynamic> json) =>
      ExitStatusModel(
        status: json['status'] as String,
        flatId: json['flat_id'] as String?,
        flatName: json['flat_name'] as String?,
        settlement: json['settlement'] != null
            ? SettlementModel.fromJson(
                json['settlement'] as Map<String, dynamic>,
              )
            : null,
      );
}
