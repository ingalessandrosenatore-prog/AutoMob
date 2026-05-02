import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle.dart';

class VehicleModel extends Vehicle {
  VehicleModel({
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
    super.powerCv,
    super.displacementCc,
    super.nextRevisionDate,
    super.lastTagliandoKm,
    super.lastDistribuzioneKm,
    super.lastTireChangeKm,
    super.lastTireRotationKm,
    super.updatedAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    String _str(dynamic v, {String fallback = ''}) =>
        v == null ? fallback : v.toString();

    int _int(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    int? _intOrNull(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    DateTime _date(dynamic v, {DateTime? fallback}) {
      if (v == null) return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ??
          (fallback ?? DateTime.fromMillisecondsSinceEpoch(0));
    }

    DateTime? _dateOrNull(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return VehicleModel(
      id: _str(json['id']),
      ownerId: _str(json['owner_id']),
      plate: _str(json['plate']),
      brand: _str(json['brand']),
      model: _str(json['model']),
      year: _int(json['year']),
      fuel: _str(json['fuel']),
      kmCurrent: _int(json['km_current']),
      powerCv: _intOrNull(json['power_cv']),
      displacementCc: _intOrNull(json['displacement_cc']),
      nextRevisionDate: _dateOrNull(json['next_revision_date']),
      tagliandoIntervalKm: _int(json['tagliando_interval_km']),
      tireChangeIntervalKm: _int(json['tire_change_interval_km']),
      tireRotationIntervalKm: _int(json['tire_rotation_interval_km']),
      lastTagliandoKm: _intOrNull(json['last_tagliando_km']),
      lastDistribuzioneKm: _intOrNull(json['last_distribuzione_km']),
      lastTireChangeKm: _intOrNull(json['last_tire_change_km']),
      lastTireRotationKm: _intOrNull(json['last_tire_rotation_km']),
      createdAt: _date(json['created_at']),
      updatedAt: _dateOrNull(json['updated_at']),
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
      'next_revision_date': nextRevisionDate?.toIso8601String(),
      'tagliando_interval_km': tagliandoIntervalKm,
      'tire_change_interval_km': tireChangeIntervalKm,
      'tire_rotation_interval_km': tireRotationIntervalKm,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
