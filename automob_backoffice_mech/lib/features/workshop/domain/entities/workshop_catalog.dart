import 'package:equatable/equatable.dart';

import '../../../service_requests/domain/entities/warning_light_observation.dart';
import 'workshop_vehicle_work_item.dart';

export 'workshop_vehicle_work_item.dart';

final class WorkshopMechanic extends Equatable {
  const WorkshopMechanic({
    required this.displayName,
    this.businessName,
    this.mechanicCode,
  });

  final String displayName;
  final String? businessName;
  final String? mechanicCode;

  @override
  List<Object?> get props => [displayName, businessName, mechanicCode];
}

final class WorkshopVehicle extends Equatable {
  const WorkshopVehicle({
    required this.id,
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    required this.kmCurrent,
    required this.tagliandoIntervalKm,
    required this.requiresMaintenance,
    this.warningLights = const [],
    this.mandatoryWorks = const [],
    this.userProblems = const [],
    this.estimatedRevenueEuro = defaultEstimatedRevenueEuro,
    this.fuel,
    this.powerCv,
    this.displacementCc,
    this.revisionDeadline,
    this.distributionIntervalKm,
    this.tireChangeIntervalKm,
    this.tireRotationIntervalKm,
    this.lastTagliandoKm,
    this.lastDistributionKm,
    this.createdAt,
    this.updatedAt,
  });

  static const int defaultEstimatedRevenueEuro = 150;

  final String id;
  final String plate;
  final String brand;
  final String model;
  final int year;
  final String? fuel;
  final int? powerCv;
  final int? displacementCc;
  final int kmCurrent;
  final DateTime? revisionDeadline;
  final int tagliandoIntervalKm;
  final int? distributionIntervalKm;
  final int? tireChangeIntervalKm;
  final int? tireRotationIntervalKm;
  final int? lastTagliandoKm;
  final int? lastDistributionKm;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool requiresMaintenance;
  final List<WarningLightObservation> warningLights;
  final List<WorkshopMandatoryWork> mandatoryWorks;
  final List<WorkshopUserProblem> userProblems;
  final int estimatedRevenueEuro;

  String get displayName => '$brand $model'.trim();

  int get totalPendingWorksCount => mandatoryWorks.length + userProblems.length;

  bool get hasPendingWorks =>
      requiresMaintenance ||
      mandatoryWorks.isNotEmpty ||
      userProblems.isNotEmpty;

  WorkshopVehicle copyWith({
    bool? requiresMaintenance,
    List<WorkshopMandatoryWork>? mandatoryWorks,
    List<WorkshopUserProblem>? userProblems,
    int? estimatedRevenueEuro,
  }) => WorkshopVehicle(
    id: id,
    plate: plate,
    brand: brand,
    model: model,
    year: year,
    fuel: fuel,
    powerCv: powerCv,
    displacementCc: displacementCc,
    kmCurrent: kmCurrent,
    revisionDeadline: revisionDeadline,
    tagliandoIntervalKm: tagliandoIntervalKm,
    distributionIntervalKm: distributionIntervalKm,
    tireChangeIntervalKm: tireChangeIntervalKm,
    tireRotationIntervalKm: tireRotationIntervalKm,
    lastTagliandoKm: lastTagliandoKm,
    lastDistributionKm: lastDistributionKm,
    createdAt: createdAt,
    updatedAt: updatedAt,
    requiresMaintenance: requiresMaintenance ?? this.requiresMaintenance,
    warningLights: warningLights,
    mandatoryWorks: mandatoryWorks ?? this.mandatoryWorks,
    userProblems: userProblems ?? this.userProblems,
    estimatedRevenueEuro: estimatedRevenueEuro ?? this.estimatedRevenueEuro,
  );

  @override
  List<Object?> get props => [
    id,
    plate,
    brand,
    model,
    year,
    fuel,
    powerCv,
    displacementCc,
    kmCurrent,
    revisionDeadline,
    tagliandoIntervalKm,
    distributionIntervalKm,
    tireChangeIntervalKm,
    tireRotationIntervalKm,
    lastTagliandoKm,
    lastDistributionKm,
    createdAt,
    updatedAt,
    requiresMaintenance,
    warningLights,
    mandatoryWorks,
    userProblems,
    estimatedRevenueEuro,
  ];
}

final class WorkshopCatalog extends Equatable {
  const WorkshopCatalog({required this.mechanic, required this.vehicles});

  final WorkshopMechanic mechanic;
  final List<WorkshopVehicle> vehicles;

  @override
  List<Object?> get props => [mechanic, vehicles];
}
