import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle.dart';

class VehicleModel extends Vehicle {
  const VehicleModel({
    required super.id,
    required super.ownerId,
    required super.plate,
    required super.brand,
    required super.model,
    required super.year,
    required super.fuel,
    required super.kmCurrent,
    required super.tagliandoIntervalKm,
    required super.tireChangeIntervalKm,
    required super.tireRotationIntervalKm,
    required super.createdAt,
    super.distribuzioneIntervalKm,
    super.powerCv,
    super.displacementCc,
    super.nextRevisionDate,
    super.lastTagliandoKm,
    super.lastTagliandoDate,
    super.lastDistribuzioneKm,
    super.lastDistribuzioneDate,
    super.lastTireChangeKm,
    super.lastTireChangeDate,
    super.lastTireRotationKm,
    super.lastTireRotationDate,
    super.lastRevisionDate,
    super.updatedAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v, {String fallback = ''}) =>
        v == null ? fallback : v.toString();

    int intValue(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    int? intOrNull(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    DateTime date(dynamic v, {DateTime? fallback}) {
      if (v == null) return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ??
          (fallback ?? DateTime.fromMillisecondsSinceEpoch(0));
    }

    DateTime? dateOrNull(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return VehicleModel(
      id: str(json['id']),
      ownerId: str(json['owner_id']),
      plate: str(json['plate']),
      brand: str(json['brand']),
      model: str(json['model']),
      year: intValue(json['year']),
      fuel: str(json['fuel']),
      kmCurrent: intValue(json['km_current']),
      powerCv: intOrNull(json['power_cv']),
      displacementCc: intOrNull(json['displacement_cc']),
      nextRevisionDate: dateOrNull(json['scadenza_revision_date']),
      tagliandoIntervalKm: intValue(
        json['tagliando_interval_km'],
        fallback: 15000,
      ),
      tireChangeIntervalKm: intValue(
        json['tire_change_interval_km'],
        fallback: 40000,
      ),
      tireRotationIntervalKm: intValue(
        json['tire_rotation_interval_km'],
        fallback: 10000,
      ),
      distribuzioneIntervalKm: intOrNull(json['distribution_intervall_km']),
      lastTagliandoKm: intOrNull(json['last_tagliando_km']),
      lastTagliandoDate: dateOrNull(json['last_tagliando_date']),
      lastDistribuzioneKm: intOrNull(json['last_distribuzione_km']),
      lastDistribuzioneDate: dateOrNull(json['last_distribuzione_date']),
      lastTireChangeKm: intOrNull(json['last_tire_change_km']),
      lastTireChangeDate: dateOrNull(json['last_tire_change_date']),
      lastTireRotationKm: intOrNull(json['last_tire_rotation_km']),
      lastTireRotationDate: dateOrNull(json['last_tire_rotation_date']),
      lastRevisionDate: dateOrNull(json['last_revision_date']),
      createdAt: date(json['created_at']),
      updatedAt: dateOrNull(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'plate': plate,
      'brand': brand,
      'model': model,
      'year': year,
      'fuel': fuel,
      'power_cv': powerCv,
      'displacement_cc': displacementCc,
      'km_current': kmCurrent,
      'scadenza_revision_date': nextRevisionDate?.toIso8601String(),
      'tagliando_interval_km': tagliandoIntervalKm,
      'tire_change_interval_km': tireChangeIntervalKm,
      'tire_rotation_interval_km': tireRotationIntervalKm,
      'distribution_intervall_km': distribuzioneIntervalKm,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
