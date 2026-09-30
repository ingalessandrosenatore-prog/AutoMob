import 'package:automob_work_log/automob_work_log.dart';

import '../../../core/types/enum_pop_up.dart';
import '../../vehicle/domain/entities/maintenance_kpi.dart';
import '../../vehicle/domain/entities/vehicle.dart';

WorkLogDetailLaunch maintenanceKpiWorkLogLaunch(
  Vehicle vehicle,
  MaintenanceKpi kpi,
) {
  final baseline = _maintenanceBaseline(vehicle, kpi.type);
  return WorkLogDetailLaunch(
    currentKm: vehicle.kmCurrent,
    vehicleName: '${vehicle.brand} ${vehicle.model}'.trim(),
    entry: WorkLogEntry(
      id: 'kpi-${vehicle.id}-${kpi.type.dbValue}',
      vehicleId: vehicle.id,
      type: kpi.type.dbValue,
      serviceKm: baseline.serviceKm,
      serviceDate: baseline.serviceDate,
      intervalKm: baseline.intervalKm,
    ),
  );
}

({int serviceKm, DateTime serviceDate, int? intervalKm}) _maintenanceBaseline(
  Vehicle vehicle,
  EnumPopUp type,
) => switch (type) {
  EnumPopUp.aggiornaTagliando => (
    serviceKm: vehicle.lastTagliandoKm ?? 0,
    serviceDate: vehicle.lastTagliandoDate ?? vehicle.createdAt,
    intervalKm: vehicle.tagliandoIntervalKm,
  ),
  EnumPopUp.aggiornaDistribuzione => (
    serviceKm: vehicle.lastDistribuzioneKm ?? 0,
    serviceDate: vehicle.lastDistribuzioneDate ?? vehicle.createdAt,
    intervalKm: vehicle.distribuzioneIntervalKm,
  ),
  EnumPopUp.aggiornaCambioGomme => (
    serviceKm: vehicle.lastTireChangeKm ?? 0,
    serviceDate: vehicle.lastTireChangeDate ?? vehicle.createdAt,
    intervalKm: vehicle.tireChangeIntervalKm,
  ),
  EnumPopUp.pneumaticiInversione => (
    serviceKm: vehicle.lastTireRotationKm ?? 0,
    serviceDate: vehicle.lastTireRotationDate ?? vehicle.createdAt,
    intervalKm: vehicle.tireRotationIntervalKm,
  ),
  EnumPopUp.revisione => (
    serviceKm: vehicle.kmCurrent,
    serviceDate: vehicle.lastRevisionDate ?? vehicle.createdAt,
    intervalKm: null,
  ),
  EnumPopUp.altro => (
    serviceKm: vehicle.kmCurrent,
    serviceDate: vehicle.createdAt,
    intervalKm: null,
  ),
};
