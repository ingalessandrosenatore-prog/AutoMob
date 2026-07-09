import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle.dart';

/// Fixture riutilizzabile: costruisce un [Vehicle] valido con valori di default,
/// sovrascrivibili quando servono per il singolo test.
Vehicle vehicleFixture({
  String id = 'v1',
  String plate = 'AB123CD',
  int kmCurrent = 10000,
  String? fotoPath,
}) {
  return Vehicle(
    id: id,
    ownerId: 'owner1',
    plate: plate,
    brand: 'Fiat',
    model: 'Panda',
    year: 2020,
    fuel: 'benzina',
    kmCurrent: kmCurrent,
    tagliandoIntervalKm: 15000,
    tireChangeIntervalKm: 40000,
    tireRotationIntervalKm: 10000,
    createdAt: DateTime(2024, 1, 1),
    fotoPath: fotoPath,
  );
}
