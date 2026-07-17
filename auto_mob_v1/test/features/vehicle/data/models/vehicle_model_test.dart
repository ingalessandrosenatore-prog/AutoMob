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
  });
}
