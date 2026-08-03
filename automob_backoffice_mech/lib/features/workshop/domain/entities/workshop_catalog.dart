import 'package:equatable/equatable.dart';

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

  String get displayName => '$brand $model'.trim();

  WorkshopVehicle copyWith({bool? requiresMaintenance}) => WorkshopVehicle(
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
  ];
}

final class WorkshopCatalog extends Equatable {
  const WorkshopCatalog({required this.mechanic, required this.vehicles});

  final WorkshopMechanic mechanic;
  final List<WorkshopVehicle> vehicles;

  @override
  List<Object?> get props => [mechanic, vehicles];
}
