import '../../domain/entities/service_request.dart';
import '../../domain/entities/service_request_report.dart';
import 'warning_light_observation_model.dart';

class ServiceRequestModel extends ServiceRequest {
  const ServiceRequestModel({
    required super.id,
    super.reports,
    required super.vehicleModel,
    required super.plate,
    required super.issues,
    required super.registeredAt,
    required super.reminderDate,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    final rawIssues = json['issues'];
    return ServiceRequestModel(
      id: json['id'] as String,
      reports: json['reports'] is List
          ? (json['reports'] as List)
                .map((item) {
                  final row = Map<String, dynamic>.from(item as Map);
                  return ServiceRequestReport(
                    recordId: row['record_id'] as String,
                    description: row['description'] as String? ?? '',
                    onboardMessage: row['onboard_message'] as String? ?? '',
                    warningLights: parseWarningLights(row['warning_lights']),
                  );
                })
                .toList(growable: false)
          : const [],
      vehicleModel: json['vehicle_model'] as String,
      plate: json['plate'] as String,
      issues: rawIssues is List
          ? rawIssues.whereType<String>().toList(growable: false)
          : const [],
      registeredAt: DateTime.parse(json['registered_at'] as String),
      reminderDate: DateTime.parse(json['reminder_date'] as String),
    );
  }
}
