import 'package:auto_mob_v1/features/dashboard/domain/usecases/calculate_maintenance_cost.dart';
import 'package:auto_mob_v1/features/dashboard/domain/entities/maintenance_cost_period.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  const calculate = CalculateMaintenanceCost();

  test('calcola le medie giornaliera, mensile e annuale in centesimi', () {
    final vehicle = vehicleFixture(
      maintenanceCostCents: 120000,
      firstMaintenanceDate: DateTime(2024, 6, 1),
      maintenanceCostsByYear: const {2024: 30000, 2025: 40000, 2026: 50000},
    );

    expect(calculate(vehicle, MaintenanceCostPeriod.daily), 329);
    expect(calculate(vehicle, MaintenanceCostPeriod.monthly), 10000);
    expect(
      calculate(
        vehicle,
        MaintenanceCostPeriod.annual,
        now: DateTime(2026, 9, 13),
      ),
      40000,
    );
  });

  test('senza lavori restituisce zero per ogni periodo', () {
    final vehicle = vehicleFixture();

    for (final period in MaintenanceCostPeriod.values) {
      expect(calculate(vehicle, period), 0);
    }
  });
}
