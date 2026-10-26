import 'service_request_report.dart';

class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.vehicleModel,
    required this.plate,
    required this.issues,
    this.estimatedCost,
    this.reports = const [],
    required this.registeredAt,
    required this.reminderDate,
  });
  final List<ServiceRequestReport> reports;
  final String id;
  final String vehicleModel;
  final String plate;
  final List<String> issues;
  final int? estimatedCost;
  final DateTime registeredAt;
  final DateTime reminderDate;
}
