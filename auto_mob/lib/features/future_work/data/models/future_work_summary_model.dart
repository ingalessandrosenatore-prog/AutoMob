import '../../domain/entities/future_work_summary.dart';

class FutureWorkSummaryModel extends FutureWorkSummary {
  const FutureWorkSummaryModel({
    required super.id,
    required super.recordId,
    required super.vehicleId,
    required super.description,
    required super.registeredAt,
    required super.reminderDate,
  });

  factory FutureWorkSummaryModel.fromJson(Map<String, dynamic> json) {
    return FutureWorkSummaryModel(
      id: json['id'].toString(),
      recordId: json['record_id'].toString(),
      vehicleId: json['vehicle_id'].toString(),
      description: json['description'].toString(),
      registeredAt: DateTime.parse(json['registered_at'].toString()),
      reminderDate: DateTime.parse(json['reminder_date'].toString()),
    );
  }
}
