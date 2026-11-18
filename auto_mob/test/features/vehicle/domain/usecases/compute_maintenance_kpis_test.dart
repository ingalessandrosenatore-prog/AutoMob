// =====================================================================
//  GOLDEN TEST — USE CASE (logica pura, nessun repository da mockare)
// ---------------------------------------------------------------------
//  ComputeMaintenanceKpis e' puro calcolo su un Vehicle: si verifica
//  direttamente l'output per diversi scenari, senza mock.
// =====================================================================

import 'package:auto_mob_v1/core/types/enum_pop_up.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/maintenance_kpi.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_component_maintenance.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_maintenance_setting.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/compute_component_maintenance_kpis.dart';
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
    List<VehicleComponentMaintenance> components = const [],
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
      componentMaintenance: components,
      createdAt: DateTime(2024, 1, 1),
    );
  }

  test(
    'tagliando usa scadenze distinte e il limite annuale anche con km residui',
    () {
      final vehicle = buildVehicle(
        kmCurrent: 20000,
        components: [
          VehicleComponentMaintenance(
            partId: 15,
            intervalKm: 15000,
            intervalYears: 1,
            lastServiceKm: 19000,
            lastServiceDate: DateTime(2025, 11, 30),
          ),
          const VehicleComponentMaintenance(
            partId: 16,
            intervalKm: 15000,
            lastServiceKm: 20000,
          ),
        ],
      );
      final service = computeComponentMaintenanceKpis(
        vehicle,
        DateTime(2026, 11, 18),
      ).firstWhere((kpi) => kpi.group == VehicleMaintenanceGroup.service);
      expect(service.components.first.percentage, lessThan(20));
      expect(service.components.first.remainingKm, 14000);
      expect(service.components.last.percentage, 100);
      expect(service.percentage, closeTo((100 + 12 / 365 * 100) / 2, .001));
    },
  );

  test('freni pesa il liquido al 50% e ogni asse al 25%', () {
    final vehicle = buildVehicle(
      kmCurrent: 40000,
      components: const [
        VehicleComponentMaintenance(
          partId: 20,
          intervalKm: 40000,
          lastServiceKm: 40000,
        ),
        VehicleComponentMaintenance(
          partId: 21,
          intervalKm: 40000,
          lastServiceKm: 0,
        ),
        VehicleComponentMaintenance(
          partId: 26,
          intervalKm: 100000,
          lastServiceKm: 40000,
        ),
      ],
    );
    final brakes = usecase(
      vehicle,
    ).firstWhere((kpi) => kpi.group == VehicleMaintenanceGroup.brakes);
    expect(brakes.percentage, 75);
    expect(brakes.components.first.percentage, 50);
    expect(brakes.components.first.alertPercentage, 0);
    expect(brakes.components.first.parts.map((pad) => pad.percentage), [
      100,
      0,
    ]);
    expect(brakes.hasUnknownComponents, isFalse);
  });

  test('Candele compare una sola volta nel KPI Tagliando', () {
    final vehicle = buildVehicle(
      components: const [
        VehicleComponentMaintenance(
          partId: 15,
          intervalKm: 15000,
          lastServiceKm: 10000,
        ),
        VehicleComponentMaintenance(
          partId: 7,
          intervalKm: 60000,
          lastServiceKm: 0,
        ),
      ],
    );
    final kpis = usecase(vehicle);
    final service = kpis.firstWhere(
      (kpi) => kpi.group == VehicleMaintenanceGroup.service,
    );
    expect(service.components.map((part) => part.label), [
      'Filtro olio',
      'Candele',
    ]);
    expect(
      kpis.any((kpi) => kpi.group == VehicleMaintenanceGroup.engine),
      isFalse,
    );
  });

  test(
    'Trasmissione mostra i due oli e include il differenziale solo se configurato',
    () {
      const gearbox = VehicleComponentMaintenance(
        partId: 201,
        intervalKm: 80000,
        lastServiceKm: 10000,
      );
      const differential = VehicleComponentMaintenance(
        partId: 202,
        intervalKm: 80000,
        lastServiceKm: 0,
      );
      final withDifferential = usecase(
        buildVehicle(
          kmCurrent: 80000,
          components: const [gearbox, differential],
        ),
      );
      final combined = withDifferential.singleWhere(
        (kpi) => kpi.group == VehicleMaintenanceGroup.gearbox,
      );
      expect(combined.components.map((part) => part.label), [
        'Olio cambio',
        'Olio differenziale',
      ]);
      expect(combined.percentage, 6.25);
      expect(
        withDifferential.any(
          (kpi) => kpi.group == VehicleMaintenanceGroup.differential,
        ),
        isFalse,
      );
      final without = usecase(buildVehicle(components: const [gearbox]));
      expect(
        without
            .singleWhere((kpi) => kpi.group == VehicleMaintenanceGroup.gearbox)
            .components
            .single
            .label,
        'Olio cambio',
      );
    },
  );

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
