import 'package:auto_mob_v1/features/vehicle/data/models/vehicle_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mappa il meccanico collegato nel veicolo', () {
    final vehicle = VehicleModel.fromJson(const {
      'id': 'vehicle-1',
      'owner_id': 'owner-1',
      'plate': 'AB123CD',
      'brand': 'Fiat',
      'model': 'Panda',
      'year': 2020,
      'fuel': 'benzina',
      'km_current': 12000,
      'km_updated_at': '2026-07-18T10:00:00Z',
      'created_at': '2026-07-16T10:00:00Z',
      'mechanic': {
        'id': 'mechanic-1',
        'mechanic_code': 'OFF-001',
        'business_name': 'Officina Giordano',
        'address': 'Via Roma 10',
        'number': '+39 081 1234567',
        'email': 'info@officinagiordano.it',
      },
    });

    expect(vehicle.mechanic?.businessName, 'Officina Giordano');
    expect(vehicle.mechanic?.address, 'Via Roma 10');
    expect(vehicle.mechanic?.phone, '+39 081 1234567');
    expect(vehicle.mechanic?.email, 'info@officinagiordano.it');
    expect(vehicle.mechanic?.photoUrl, isNull);
    expect(vehicle.kmUpdatedAt, DateTime.utc(2026, 7, 18, 10));
  });

  test('accetta un veicolo senza meccanico collegato', () {
    final vehicle = VehicleModel.fromJson(const {
      'id': 'vehicle-1',
      'owner_id': 'owner-1',
      'plate': 'AB123CD',
      'brand': 'Fiat',
      'model': 'Panda',
      'year': 2020,
      'fuel': 'benzina',
      'km_current': 12000,
      'created_at': '2026-07-16T10:00:00Z',
    });

    expect(vehicle.mechanic, isNull);
    expect(vehicle.mechanics, isEmpty);
  });

  test('mappa tutte le officine mantenendo il getter legacy', () {
    final vehicle = VehicleModel.fromJson(const {
      'id': 'vehicle-1',
      'owner_id': 'owner-1',
      'plate': 'AB123CD',
      'brand': 'Fiat',
      'model': 'Panda',
      'year': 2020,
      'fuel': 'benzina',
      'km_current': 12000,
      'created_at': '2026-07-16T10:00:00Z',
      'mechanics': [
        {
          'id': 'mechanic-2',
          'mechanic_code': 'OFF-002',
          'business_name': 'Elettrauto Rossi',
        },
        {
          'id': 'mechanic-1',
          'mechanic_code': 'OFF-001',
          'business_name': 'Officina Giordano',
        },
      ],
    });

    expect(vehicle.mechanics, hasLength(2));
    expect(vehicle.mechanics.first.businessName, 'Elettrauto Rossi');
    expect(vehicle.mechanic, vehicle.mechanics.first);
    expect(vehicle.toJson()['mechanics'], hasLength(2));
  });
}
