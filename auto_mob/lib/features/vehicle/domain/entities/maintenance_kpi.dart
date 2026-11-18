import 'package:equatable/equatable.dart';

import 'package:auto_mob_v1/core/types/enum_pop_up.dart';

import 'vehicle_maintenance_setting.dart';

class MaintenanceComponentKpi extends Equatable {
  const MaintenanceComponentKpi({
    required this.label,
    required this.percentage,
    this.remainingKm,
    this.dueDate,
    this.parts = const [],
  });

  final String label;
  final double? percentage;
  final int? remainingKm;
  final DateTime? dueDate;
  final List<MaintenanceComponentKpi> parts;

  double? get alertPercentage => parts.fold<double?>(percentage, (
    lowest,
    part,
  ) {
    final value = part.alertPercentage;
    return value != null && (lowest == null || value < lowest) ? value : lowest;
  });

  @override
  List<Object?> get props => [label, percentage, remainingKm, dueDate, parts];
}

/// KPI di una manutenzione "a chilometri" (tagliando, distribuzione, gomme...).
/// E' un valore CALCOLATO (non sta sul DB): dice quanti km mancano al prossimo
/// intervento e la percentuale di "vita" residua rispetto all'intervallo.
class MaintenanceKpi extends Equatable {
  /// Di che manutenzione si tratta (riusa l'enum condiviso in core/types).
  final EnumPopUp type;

  /// Km mancanti al prossimo intervento. Negativo = gia' scaduto.
  final int remainingKm;

  /// 0..100: quanto manca, in percentuale, rispetto all'intervallo.
  final double percentage;
  final VehicleMaintenanceGroup? group;
  final List<MaintenanceComponentKpi> components;
  final DateTime? lastInspectionDate;

  bool get hasUnknownComponents => components.any(
    (component) =>
        component.percentage == null ||
        component.parts.any((part) => part.percentage == null),
  );

  const MaintenanceKpi({
    required this.type,
    required this.remainingKm,
    required this.percentage,
    this.group,
    this.components = const [],
    this.lastInspectionDate,
  });

  @override
  List<Object?> get props => [
    type,
    remainingKm,
    percentage,
    group,
    components,
    lastInspectionDate,
  ];
}
