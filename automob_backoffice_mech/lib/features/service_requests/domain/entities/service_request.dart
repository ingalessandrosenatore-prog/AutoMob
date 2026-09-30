class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.vehicleModel,
    required this.plate,
    required this.issues,
    this.estimatedCost,
    required this.registeredAt,
    required this.reminderDate,
  });
  final String id;
  final String vehicleModel;
  final String plate;
  final List<String> issues;
  final int? estimatedCost;
  final DateTime registeredAt;
  final DateTime reminderDate;
}
