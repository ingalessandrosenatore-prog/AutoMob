import 'package:equatable/equatable.dart';

import '../../../service_requests/domain/entities/warning_light_observation.dart';

enum WorkshopMandatoryWorkType { tagliando, distribution }

final class WorkshopMandatoryWork extends Equatable {
  const WorkshopMandatoryWork({
    required this.type,
    required this.title,
    required this.dueKm,
    required this.currentKm,
  });

  final WorkshopMandatoryWorkType type;
  final String title;
  final int dueKm;
  final int currentKm;

  @override
  List<Object?> get props => [type, title, dueKm, currentKm];
}

final class WorkshopUserProblem extends Equatable {
  const WorkshopUserProblem({
    required this.id,
    required this.description,
    this.onboardMessage = '',
    this.warningLights = const [],
    this.registeredAt,
    this.reportedKm,
  });

  final String id;
  final String description;
  final String onboardMessage;
  final List<WarningLightObservation> warningLights;
  final DateTime? registeredAt;
  final int? reportedKm;

  @override
  List<Object?> get props => [
    id,
    description,
    onboardMessage,
    warningLights,
    registeredAt,
    reportedKm,
  ];
}
