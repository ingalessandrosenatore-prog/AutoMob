import 'package:auto_mob_v1/features/vehicle/data/datasources/vehicle_remote_data_source.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  group('toSupabasePayload', () {
    test('applica tutti i default quando i lavori iniziali sono vuoti', () {
      final dataSource = VehicleRemoteDataSourceImpl(
        supabaseClient: SupabaseClient('https://example.supabase.co', 'test'),
      );

      final payload = dataSource.toSupabasePayload(const VehicleDraft());
      final vehicle = payload['veicolo'] as Map<String, dynamic>;
      final works = payload['lavori'] as List<Map<String, dynamic>>;

      expect(vehicle['tagliando_interval_km'], 15000);
      expect(vehicle['distribution_intervall_km'], 100000);
      expect(vehicle['tire_change_interval_km'], 40000);
      expect(vehicle['tire_rotation_interval_km'], 15000);
      expect(vehicle['scadenza_revision_date'], isNull);
      expect(works, [
        {'type': 'tagliando', 'service_km': 0},
        {'type': 'distribuzione', 'service_km': 0},
        {'type': 'pneumatici_cambio', 'service_km': 0},
        {'type': 'pneumatici_inversione', 'service_km': 0},
      ]);
    });
  });
}
