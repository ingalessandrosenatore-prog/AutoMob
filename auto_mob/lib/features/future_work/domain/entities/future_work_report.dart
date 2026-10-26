import 'package:equatable/equatable.dart';

import 'warning_light_observation.dart';

class FutureWorkReport extends Equatable {
  const FutureWorkReport({
    required this.id,
    required this.vehicleId,
    required this.description,
    this.onboardMessage = '',
    this.warningLights = const [],
    required this.reminderDate,
  });

  final String id;
  final String vehicleId;
  final String description;
  final String onboardMessage;
  final List<WarningLightObservation> warningLights;
  final DateTime reminderDate;

  @override
  List<Object> get props => [
    id,
    vehicleId,
    description,
    onboardMessage,
    warningLights,
    reminderDate,
  ];
}
