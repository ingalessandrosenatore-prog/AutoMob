import 'package:auto_mob_v1/features/vehicle/data/datasources/vehicle_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeFuel', () {
    test('normalizza le etichette ibride della UI', () {
      expect(
        VehicleRemoteDataSourceImpl.normalizeFuel('Ibrido Mild (MHEV)'),
        'ibrido',
      );
      expect(
        VehicleRemoteDataSourceImpl.normalizeFuel('Ibrido Plug-in (PHEV)'),
        'ibrido',
      );
    });

    test('normalizza le alimentazioni combinate', () {
      expect(VehicleRemoteDataSourceImpl.normalizeFuel('Benzina + GPL'), 'gpl');
      expect(
        VehicleRemoteDataSourceImpl.normalizeFuel('Metano + Benzina'),
        'metano',
      );
    });

    test('mantiene idrogeno come valore canonico', () {
      expect(VehicleRemoteDataSourceImpl.normalizeFuel('Idrogeno'), 'idrogeno');
    });
  });
}
