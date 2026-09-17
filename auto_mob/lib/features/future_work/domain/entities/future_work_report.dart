import 'package:equatable/equatable.dart';

class FutureWorkReport extends Equatable {
  const FutureWorkReport({
    required this.id,
    required this.vehicleId,
    required this.description,
    required this.reminderDate,
  });

  final String id;
  final String vehicleId;
  final String description;
  final DateTime reminderDate;

  @override
  List<Object> get props => [id, vehicleId, description, reminderDate];
}
