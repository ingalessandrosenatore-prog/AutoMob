import '../../../vehicle/domain/entities/vehicle.dart';
import '../entities/maintenance_cost_period.dart';

class GetFuelCostForPeriod {
  const GetFuelCostForPeriod();

  int call(Vehicle vehicle, MaintenanceCostPeriod period) => switch (period) {
    MaintenanceCostPeriod.daily => vehicle.fuelCostAverages.dailyCents,
    MaintenanceCostPeriod.monthly => vehicle.fuelCostAverages.monthlyCents,
    MaintenanceCostPeriod.annual => vehicle.fuelCostAverages.annualCents,
  };
}
