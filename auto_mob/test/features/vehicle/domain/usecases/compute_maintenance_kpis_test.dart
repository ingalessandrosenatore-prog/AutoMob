// =====================================================================
//  GOLDEN TEST — USE CASE (logica pura, nessun repository da mockare)
// ---------------------------------------------------------------------
//  ComputeMaintenanceKpis e' puro calcolo su un Vehicle: si verifica
//  direttamente l'output per diversi scenari, senza mock.
// =====================================================================

import 'package:auto_mob_v1/core/types/enum_pop_up.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/maintenance_kpi.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/compute_maintenance_kpis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ComputeMaintenanceKpis usecase;

  setUp(() {
    usecase = ComputeMaintenanceKpis();
  });

  Vehicle buildVehicle({
    int kmCurrent = 10000,
    int tagliandoIntervalKm = 15000,
    int tireChangeIntervalKm = 40000,
    int tireRotationIntervalKm = 10000,
    int? distribuzioneIntervalKm,
    int? lastTagliandoKm,
    int? lastDistribuzioneKm,
    int? lastTireChangeKm,
    int? lastTireRotationKm,
  }) {
    return Vehicle(
      id: 'v1',
      ownerId: 'owner1',
      plate: 'AB123CD',
      brand: 'Fiat',
      model: 'Panda',
      year: 2020,
      fuel: 'benzina',
      kmCurrent: kmCurrent,
      tagliandoIntervalKm: tagliandoIntervalKm,
      tireChangeIntervalKm: tireChangeIntervalKm,
      tireRotationIntervalKm: tireRotationIntervalKm,
      distribuzioneIntervalKm: distribuzioneIntervalKm,
      lastTagliandoKm: lastTagliandoKm,
      lastDistribuzioneKm: lastDistribuzioneKm,
      lastTireChangeKm: lastTireChangeKm,
      lastTireRotationKm: lastTireRotationKm,
      createdAt: DateTime(2024, 1, 1),
    );
  }

  test('ritorna lista vuota per il veicolo placeholder', () {
    final result = usecase(Vehicle.placeholder());

    expect(result, isEmpty);
  });

  test(
    'Fiat 500 senza storico usa base zero e tutti gli intervalli default',
    () {
      final vehicle = buildVehicle(distribuzioneIntervalKm: null);

      final result = usecase(vehicle);

      expect(result, hasLength(4));
      expect(
        result
            .firstWhere((k) => k.type == EnumPopUp.aggiornaTagliando)
            .remainingKm,
        5000,
      );
      expect(
        result
            .firstWhere((k) => k.type == EnumPopUp.aggiornaDistribuzione)
            .remainingKm,
        90000,
      );
    },
  );

  test('include la distribuzione quando l\'intervallo e\' configurato', () {
    final vehicle = buildVehicle(distribuzioneIntervalKm: 20000);

    final result = usecase(vehicle);

    expect(
      result.map((k) => k.type),
      contains(EnumPopUp.aggiornaDistribuzione),
    );
    expect(result, hasLength(4));
  });

  test('senza storico la base resta zero dopo un aggiornamento dei km', () {
    final vehicle = buildVehicle(
      kmCurrent: 10000,
      tagliandoIntervalKm: 15000,
      lastTagliandoKm: null,
    );

    final result = usecase(vehicle);
    final tagliando = result.firstWhere(
      (k) => k.type == EnumPopUp.aggiornaTagliando,
    );

    expect(tagliando.remainingKm, 5000);
    expect(tagliando.percentage, closeTo(33.33, 0.01));
  });

  test('con storico calcola i km mancanti rispetto all\'ultimo intervento', () {
    final vehicle = buildVehicle(
      kmCurrent: 12000,
      tagliandoIntervalKm: 15000,
      lastTagliandoKm: 5000,
    );

    final result = usecase(vehicle);
    final tagliando = result.firstWhere(
      (k) => k.type == EnumPopUp.aggiornaTagliando,
    );

    // prossimoKm = 5000 + 15000 = 20000; mancanti = 20000 - 12000 = 8000
    expect(tagliando.remainingKm, 8000);
    expect(tagliando.percentage, closeTo(53.33, 0.01));
  });

  test(
    'intervento scaduto: km mancanti negativi e percentuale clampata a 0',
    () {
      final vehicle = buildVehicle(
        kmCurrent: 30000,
        tagliandoIntervalKm: 15000,
        lastTagliandoKm: 5000,
      );

      final result = usecase(vehicle);
      final tagliando = result.firstWhere(
        (k) => k.type == EnumPopUp.aggiornaTagliando,
      );

      // prossimoKm = 20000; mancanti = 20000 - 30000 = -10000
      expect(tagliando.remainingKm, -10000);
      expect(tagliando.percentage, 0.0);
    },
  );

  test(
    'ritorna un MaintenanceKpi per ognuno dei 4 tipi quando tutti configurati',
    () {
      final vehicle = buildVehicle(distribuzioneIntervalKm: 20000);

      final result = usecase(vehicle);

      expect(result, hasLength(4));
      expect(result, everyElement(isA<MaintenanceKpi>()));
    },
  );
}
