import 'package:automob_backoffice_mech/features/workshop/data/models/workshop_catalog_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mappa il JSON completo dell RPC nel dominio', () {
    final model = WorkshopCatalogModel.fromJson({
      'mechanic': {
        'display_name': 'Marco',
        'business_name': 'Officina Marco',
        'mechanic_code': 'MEC-123',
      },
      'vehicles': [
        {
          'id': 'vehicle-1',
          'plate': 'AB123CD',
          'brand': 'Fiat',
          'model': 'Panda',
          'year': 2022,
          'fuel': 'benzina',
          'power_cv': 70,
          'displacement_cc': 999,
          'km_current': 124000,
          'scadenza_revision_date': '2027-06-30',
          'tagliando_interval_km': 15000,
          'distribution_intervall_km': 100000,
          'tire_change_interval_km': 40000,
          'tire_rotation_interval_km': 10000,
          'last_tagliando_km': 110000,
          'last_distribuzione_km': 50000,
          'created_at': '2026-01-01T10:00:00Z',
          'updated_at': '2026-07-01T10:00:00Z',
        },
      ],
    });

    final catalog = model.toEntity();
    expect(catalog.mechanic.displayName, 'Marco');
    expect(catalog.mechanic.mechanicCode, 'MEC-123');
    expect(catalog.vehicles.single.displayName, 'Fiat Panda');
    expect(catalog.vehicles.single.lastTagliandoKm, 110000);
    expect(catalog.vehicles.single.lastDistributionKm, 50000);
    expect(catalog.vehicles.single.requiresMaintenance, isFalse);
  });

  test('usa liste vuote e valori sicuri per campi opzionali mancanti', () {
    final catalog = WorkshopCatalogModel.fromJson({
      'mechanic': {'display_name': null},
      'vehicles': null,
    }).toEntity();

    expect(catalog.mechanic.displayName, 'Meccanico');
    expect(catalog.vehicles, isEmpty);
  });
}
