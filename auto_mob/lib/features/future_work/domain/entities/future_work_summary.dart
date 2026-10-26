import 'package:equatable/equatable.dart';

import 'warning_light_observation.dart';

class FutureWorkSummary extends Equatable {
  const FutureWorkSummary({
    required this.id,
    required this.recordId,
    required this.vehicleId,
    required this.description,
    this.reportedKm,
    this.onboardMessage = '',
    this.warningLights = const [],
    required this.registeredAt,
    required this.reminderDate,
  });

  final String id;
  final String recordId;
  final String vehicleId;
  final String description;
  final String onboardMessage;
  final int? reportedKm;

  String get message => onboardMessage.trim().isNotEmpty
      ? onboardMessage.trim()
      : description.trim();
  final List<WarningLightObservation> warningLights;
  final DateTime registeredAt;
  final DateTime reminderDate;

  @override
  List<Object?> get props => [
    id,
    recordId,
    vehicleId,
    description,
    onboardMessage,
    reportedKm,
    warningLights,
    registeredAt,
    reminderDate,
  ];
}
