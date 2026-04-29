import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle.dart';

class VehicleModel extends Vehicle{



  VehicleModel({required super.id, required super.ownerId, required super.plate, required super.brand, required super.model, required super.year, required super.fuel, required super.kmCurrent, required super.tagliandoIntervalKm, required super.tireChangeIntervalKm, required super.tireRotationIntervalKm, required super.createdAt});

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'],
      ownerId: json['ownerId'],
      plate: json['plate'],
      brand: json['brand'],
      model: json['model'],
      year: json['year'],
      fuel: json['fuel'],
      kmCurrent: json['kmCurrent'],
      tagliandoIntervalKm: json['tagliandoIntervalKm'],
      tireChangeIntervalKm: json['tireChangeIntervalKm'],
      tireRotationIntervalKm: json['tireRotationIntervalKm'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'plate': plate,
      'brand': brand,
      'model': model,
      'year': year,
      'fuel': fuel,
      'kmCurrent': kmCurrent,
      'tagliandoIntervalKm': tagliandoIntervalKm,
      'tireChangeIntervalKm': tireChangeIntervalKm,
      'tireRotationIntervalKm': tireRotationIntervalKm,
      'createdAt': createdAt.toIso8601String(),
    };
  }

}