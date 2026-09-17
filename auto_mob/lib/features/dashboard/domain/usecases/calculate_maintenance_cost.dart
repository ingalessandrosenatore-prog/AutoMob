import '../../../vehicle/domain/entities/vehicle.dart';
import '../entities/maintenance_cost_period.dart';

class CalculateMaintenanceCost {
  const CalculateMaintenanceCost();

  int call(Vehicle vehicle, MaintenanceCostPeriod period, {DateTime? now}) {
    final annualCosts = vehicle.maintenanceCostsByYear;
    final total = annualCosts.isEmpty
        ? vehicle.maintenanceCostCents
        : annualCosts.values.fold<int>(0, (sum, cents) => sum + cents);
    if (total <= 0) return 0;

    final divisor = switch (period) {
      MaintenanceCostPeriod.daily => 365,
      MaintenanceCostPeriod.monthly => 12,
      MaintenanceCostPeriod.annual => _recordedYears(
        vehicle.firstMaintenanceDate,
        now ?? DateTime.now(),
      ),
    };
    return (total / divisor).round();
  }

  int _recordedYears(DateTime? firstMaintenanceDate, DateTime now) {
    if (firstMaintenanceDate == null) return 1;
    return (now.year - firstMaintenanceDate.year + 1).clamp(1, 10000);
  }
}
