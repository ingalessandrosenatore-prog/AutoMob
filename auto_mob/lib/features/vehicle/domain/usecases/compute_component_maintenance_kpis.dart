import 'dart:math' as math;

import '../../../../core/types/enum_pop_up.dart';
import '../entities/maintenance_kpi.dart';
import '../entities/vehicle.dart';
import '../entities/vehicle_component_maintenance.dart';
import '../entities/vehicle_maintenance_setting.dart';

List<MaintenanceKpi> computeComponentMaintenanceKpis(
  Vehicle vehicle,
  DateTime now,
) {
  final byId = {
    for (final part in vehicle.componentMaintenance) part.partId: part,
  };
  final groups = <VehicleMaintenanceGroup, List<MaintenanceComponentKpi>>{};
  for (final field in VehicleMaintenanceField.values) {
    final rows = [
      for (final id in field.partIds)
        if (byId[id] case final part?)
          _partKpi(part, _label(field, id), vehicle.kmCurrent, now),
    ];
    if (rows.isEmpty) continue;
    final group = switch (field) {
      VehicleMaintenanceField.sparkPlugs => VehicleMaintenanceGroup.service,
      VehicleMaintenanceField.differential => VehicleMaintenanceGroup.gearbox,
      _ => field.group,
    };
    groups
        .putIfAbsent(group, () => [])
        .addAll(
          field == VehicleMaintenanceField.pads && rows.length > 1
              ? [_combinePads(rows)]
              : rows,
        );
  }
  return [
    for (final entry in groups.entries)
      MaintenanceKpi(
        type: switch (entry.key) {
          VehicleMaintenanceGroup.service => EnumPopUp.aggiornaTagliando,
          VehicleMaintenanceGroup.distribution =>
            EnumPopUp.aggiornaDistribuzione,
          VehicleMaintenanceGroup.tires => EnumPopUp.aggiornaCambioGomme,
          _ => EnumPopUp.altro,
        },
        group: entry.key,
        remainingKm: _minimumKm(entry.value) ?? 0,
        percentage: _mean(entry.value),
        components: List.unmodifiable(entry.value),
        lastInspectionDate: entry.key == VehicleMaintenanceGroup.brakes
            ? vehicle.brakeInspectionDate
            : null,
      ),
  ];
}

String _label(VehicleMaintenanceField field, int id) => switch (field) {
  VehicleMaintenanceField.oil =>
    id == field.partIds.first ? 'Filtro olio' : 'Olio motore',
  VehicleMaintenanceField.pads =>
    id == field.partIds.first ? 'Anteriori' : 'Posteriori',
  _ => field.label,
};

MaintenanceComponentKpi _partKpi(
  VehicleComponentMaintenance part,
  String label,
  int currentKm,
  DateTime now,
) {
  final limitKm = part.intervalKm;
  final startKm = part.lastServiceKm;
  final remainingKm = limitKm == null || startKm == null
      ? null
      : startKm + limitKm - currentKm;
  final kmShare = remainingKm == null || limitKm == null
      ? null
      : (remainingKm / limitKm).clamp(0.0, 1.0);

  final lastDate = part.lastServiceDate;
  final years = part.intervalYears;
  DateTime? dueDate;
  double? timeShare;
  if (lastDate != null && years != null) {
    final year = lastDate.year + years;
    final maxDay = DateTime.utc(year, lastDate.month + 1, 0).day;
    final start = DateTime.utc(lastDate.year, lastDate.month, lastDate.day);
    final today = DateTime.utc(now.year, now.month, now.day);
    dueDate = DateTime.utc(
      year,
      lastDate.month,
      math.min(lastDate.day, maxDay),
    );
    timeShare =
        (dueDate.difference(today).inDays / dueDate.difference(start).inDays)
            .clamp(0.0, 1.0);
  }
  final limitingShare = kmShare == null || timeShare == null
      ? kmShare ?? timeShare
      : math.min(kmShare, timeShare);
  return MaintenanceComponentKpi(
    label: label,
    percentage: limitingShare == null ? null : limitingShare * 100,
    remainingKm: remainingKm,
    dueDate: dueDate,
  );
}

MaintenanceComponentKpi _combinePads(List<MaintenanceComponentKpi> parts) {
  return MaintenanceComponentKpi(
    label: VehicleMaintenanceField.pads.label,
    percentage: parts.any((part) => part.percentage != null)
        ? _mean(parts)
        : null,
    remainingKm: _minimumKm(parts),
    parts: List.unmodifiable(parts),
  );
}

int? _minimumKm(List<MaintenanceComponentKpi> parts) {
  final known = parts.map((part) => part.remainingKm).whereType<int>();
  return known.isEmpty ? null : known.reduce(math.min);
}

double _mean(List<MaintenanceComponentKpi> parts) {
  final known = parts
      .map((part) => part.percentage)
      .whereType<double>()
      .toList();
  return known.isEmpty ? 0 : known.reduce((a, b) => a + b) / known.length;
}
