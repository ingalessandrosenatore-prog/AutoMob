import '../../domain/entities/service_request.dart';

class ServiceRequestModel extends ServiceRequest {
  const ServiceRequestModel({
    required super.id,
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
