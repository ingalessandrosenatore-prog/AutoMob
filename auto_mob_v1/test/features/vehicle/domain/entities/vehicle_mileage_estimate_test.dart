import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_mileage_estimate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stima i km dalla media giornaliera e dai giorni trascorsi', () {
    final estimate = VehicleMileageEstimate.calculate(
      currentKm: 166600,
      vehicleYear: 2021,
      lastKmUpdateAt: DateTime.utc(2026, 7, 2, 12),
      now: DateTime.utc(2026, 7, 20, 12),
    );

    expect(estimate.daysSinceUpdate, 18);
    expect(estimate.averageKmPerDay, closeTo(91.287, 0.001));
    expect(estimate.additionalKm, 1643);
    expect(estimate.estimatedKm, 168243);
  });

  test('senza data non aggiunge km stimati', () {
    final estimate = VehicleMileageEstimate.calculate(
      currentKm: 10000,
      vehicleYear: 2024,
      lastKmUpdateAt: null,
      now: DateTime.utc(2026, 7, 20),
    );

    expect(estimate.daysSinceUpdate, 0);
    expect(estimate.additionalKm, 0);
    expect(estimate.estimatedKm, 10000);
  });
}
