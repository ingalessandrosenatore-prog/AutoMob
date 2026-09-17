import 'package:equatable/equatable.dart';

class FutureWorkSummary extends Equatable {
  const FutureWorkSummary({
    required this.id,
    required this.recordId,
    required this.vehicleId,
    required this.description,
    required this.registeredAt,
    required this.reminderDate,
  });

  final String id;
  final String recordId;
  final String vehicleId;
  final String description;
  final DateTime registeredAt;
  final DateTime reminderDate;

  @override
  List<Object> get props => [
    id,
    recordId,
    vehicleId,
    description,
    registeredAt,
    reminderDate,
  ];
}
