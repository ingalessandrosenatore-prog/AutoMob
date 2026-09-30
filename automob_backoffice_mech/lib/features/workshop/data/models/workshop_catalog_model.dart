import '../../domain/entities/workshop_catalog.dart';

final class WorkshopCatalogModel {
  const WorkshopCatalogModel({required this.mechanic, required this.vehicles});

  factory WorkshopCatalogModel.fromJson(Map<String, dynamic> json) {
    final vehicleJson = json['vehicles'];
    return WorkshopCatalogModel(
      mechanic: WorkshopMechanicModel.fromJson(_map(json['mechanic'])),
      vehicles: vehicleJson is List
          ? vehicleJson
                .map((item) => WorkshopVehicleModel.fromJson(_map(item)))
                .toList(growable: false)
          : const [],
    );
  }

  final WorkshopMechanicModel mechanic;
  final List<WorkshopVehicleModel> vehicles;

  WorkshopCatalog toEntity() => WorkshopCatalog(
    mechanic: mechanic.toEntity(),
    vehicles: vehicles.map((vehicle) => vehicle.toEntity()).toList(),
  );
}

final class WorkshopMechanicModel {
  const WorkshopMechanicModel({
    required this.displayName,
    this.businessName,
    this.mechanicCode,
  });

  factory WorkshopMechanicModel.fromJson(Map<String, dynamic> json) =>
      WorkshopMechanicModel(
        displayName: _string(json['display_name'], fallback: 'Meccanico'),
        businessName: _nullableString(json['business_name']),
        mechanicCode: _nullableString(json['mechanic_code']),
      );

  final String displayName;
  final String? businessName;
  final String? mechanicCode;

  WorkshopMechanic toEntity() => WorkshopMechanic(
    displayName: displayName,
    businessName: businessName,
    mechanicCode: mechanicCode,
  );
}

final class WorkshopVehicleModel {
  const WorkshopVehicleModel({
    required this.id,
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    required this.kmCurrent,
    required this.tagliandoIntervalKm,
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

  factory WorkshopVehicleModel.fromJson(
    Map<String, dynamic> json,
  ) => WorkshopVehicleModel(
    id: _string(json['id']),
    plate: _string(json['plate']),
    brand: _string(json['brand']),
    model: _string(json['model']),
    year: _integer(json['year']),
    fuel: _nullableString(json['fuel']),
    powerCv: _nullableInteger(json['power_cv']),
    displacementCc: _nullableInteger(json['displacement_cc']),
    kmCurrent: _integer(json['km_current']),
    revisionDeadline: _date(json['scadenza_revision_date']),
    tagliandoIntervalKm: _integer(
      json['tagliando_interval_km'],
      fallback: 15000,
    ),
    distributionIntervalKm: _nullableInteger(json['distribution_intervall_km']),
    tireChangeIntervalKm: _nullableInteger(json['tire_change_interval_km']),
    tireRotationIntervalKm: _nullableInteger(json['tire_rotation_interval_km']),
    lastTagliandoKm: _nullableInteger(json['last_tagliando_km']),
    lastDistributionKm: _nullableInteger(json['last_distribuzione_km']),
    createdAt: _date(json['created_at']),
    updatedAt: _date(json['updated_at']),
  );

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

  WorkshopVehicle toEntity() => WorkshopVehicle(
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
    requiresMaintenance: false,
  );
}

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, item) => MapEntry(key.toString(), item))
    : const <String, dynamic>{};

String _string(Object? value, {String fallback = ''}) =>
    _nullableString(value) ?? fallback;

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _integer(Object? value, {int fallback = 0}) =>
    _nullableInteger(value) ?? fallback;

int? _nullableInteger(Object? value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  String text => int.tryParse(text),
  _ => null,
};

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());
