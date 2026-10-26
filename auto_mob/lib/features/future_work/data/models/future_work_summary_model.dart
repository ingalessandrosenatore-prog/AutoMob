import '../../domain/entities/future_work_summary.dart';
import 'warning_light_observation_model.dart';

class FutureWorkSummaryModel extends FutureWorkSummary {
  const FutureWorkSummaryModel({
    required super.id,
    required super.recordId,
    required super.vehicleId,
    required super.description,
    super.onboardMessage,
    super.reportedKm,
    super.warningLights,
    required super.registeredAt,
    required super.reminderDate,
  });

  factory FutureWorkSummaryModel.fromJson(Map<String, dynamic> json) {
    return FutureWorkSummaryModel(
      id: json['id'].toString(),
      recordId: json['record_id'].toString(),
      vehicleId: json['vehicle_id'].toString(),
      description: json['description']?.toString() ?? '',
      onboardMessage: json['onboard_message'] as String? ?? '',
      reportedKm: (json['reported_km'] as num?)?.toInt(),
      warningLights: parseWarningLights(json['warning_lights']),
      registeredAt: DateTime.parse(json['registered_at'].toString()),
      reminderDate: DateTime.parse(json['reminder_date'].toString()),
    );
  }
}
