import 'package:auto_mob_v1/core/types/enum_pop_up.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/maintenance_kpi_work_log_launch.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/maintenance_kpi.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle.dart';
import 'package:automob_work_log/automob_work_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('il KPI crea un dettaglio con tipo e scadenza coerenti', () {
    final vehicle = Vehicle(
      id: 'vehicle-1',
      ownerId: 'owner-1',
      plate: 'AB123CD',
      brand: 'Alfa Romeo',
      model: 'Giulia',
      year: 2022,
      fuel: 'benzina',
      kmCurrent: 50000,
      tagliandoIntervalKm: 15000,
      tireChangeIntervalKm: 40000,
      tireRotationIntervalKm: 10000,
      distribuzioneIntervalKm: 60000,
      lastDistribuzioneKm: 42000,
      lastDistribuzioneDate: DateTime(2026, 3, 12),
      createdAt: DateTime(2022, 1, 1),
    );
    const kpi = MaintenanceKpi(
      type: EnumPopUp.aggiornaDistribuzione,
      remainingKm: 52000,
      percentage: 86.6,
    );

    final launch = maintenanceKpiWorkLogLaunch(vehicle, kpi);

    expect(launch.entry.type, 'distribuzione');
    expect(launch.entry.serviceKm, 42000);
    expect(launch.entry.intervalKm, 60000);
    expect(launch.entry.serviceDate, DateTime(2026, 3, 12));
    expect(launch.currentKm, 50000);
    expect(launch.vehicleName, 'Alfa Romeo Giulia');

    final restored = WorkLogDetailLaunch.tryFromRouteExtra(
      launch.toRouteExtra(),
    );
    expect(restored, launch);
  });
}
