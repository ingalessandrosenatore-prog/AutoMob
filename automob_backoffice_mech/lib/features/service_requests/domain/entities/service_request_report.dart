import 'warning_light_observation.dart';

class ServiceRequestReport {
  const ServiceRequestReport({
    required this.recordId,
    required this.description,
    required this.onboardMessage,
    required this.warningLights,
  });
  final String recordId;
  final String description;
  final String onboardMessage;
  final List<WarningLightObservation> warningLights;
}
