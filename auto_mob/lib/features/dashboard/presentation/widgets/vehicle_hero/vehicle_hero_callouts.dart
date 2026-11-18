import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/types/enum_pop_up.dart';
import '../../../../vehicle/domain/entities/maintenance_kpi.dart';
import '../../../../vehicle/domain/entities/vehicle_maintenance_setting.dart';
import 'vehicle_hero_layout.dart';

class VehicleHeroCallout {
  const VehicleHeroCallout({
    required this.title,
    required this.anchor,
    required this.slot,
    required this.icon,
    required this.kpi,
    this.rotation,
  });

  final String title;
  final String? anchor;
  final VehicleHeroSlot slot;
  final List<List<dynamic>> icon;
  final MaintenanceKpi kpi;
  final MaintenanceKpi? rotation;

  bool get isRear => slot == VehicleHeroSlot.belowBrakes;
  bool get isTires =>
      kpi.type == EnumPopUp.aggiornaCambioGomme ||
      kpi.type == EnumPopUp.pneumaticiInversione;

  List<String> get meshes => switch (kpi.group) {
    VehicleMaintenanceGroup.brakes => const [
      'caliper_bridge_FL',
      'caliper_bridge_FR',
      'caliper_bridge_RL',
      'caliper_bridge_RR',
    ],
    VehicleMaintenanceGroup.gearbox => [
      for (final part in kpi.components)
        if (part.label == VehicleMaintenanceField.gearbox.label)
          'gearbox'
        else if (part.label == VehicleMaintenanceField.differential.label)
          'differential',
    ],
    VehicleMaintenanceGroup.differential => const ['differential'],
    VehicleMaintenanceGroup.lpg ||
    VehicleMaintenanceGroup.cng => const ['fuel_tank'],
    _ => switch (kpi.type) {
      EnumPopUp.aggiornaTagliando => const ['oil_pan', 'oil_filter_canister'],
      EnumPopUp.aggiornaDistribuzione => const [
        'timing_belt',
        'timing_sprocket_1',
        'timing_sprocket_2',
        'timing_sprocket_3',
      ],
      EnumPopUp.aggiornaCambioGomme ||
      EnumPopUp.pneumaticiInversione => const ['tire_RL', 'tire_RR'],
      _ => const [],
    },
  };

  static List<VehicleHeroCallout> forKpis(List<MaintenanceKpi> kpis) {
    final rotation = kpis
        .where((kpi) => kpi.type == EnumPopUp.pneumaticiInversione)
        .firstOrNull;
    final hasTires = kpis.any(
      (kpi) => kpi.type == EnumPopUp.aggiornaCambioGomme,
    );
    final items = [
      for (final kpi in kpis)
        if (kpi.group != VehicleMaintenanceGroup.engine &&
            (kpi != rotation || !hasTires))
          _forKpi(kpi, rotation),
    ];
    return items;
  }

  static VehicleHeroCallout _forKpi(
    MaintenanceKpi kpi,
    MaintenanceKpi? rotation,
  ) {
    final (title, anchor) = switch (kpi.group) {
      VehicleMaintenanceGroup.brakes => ('Freni', 'brake_disc_FL'),
      VehicleMaintenanceGroup.gearbox => (
        VehicleMaintenanceGroup.gearbox.label,
        'fuel_tank',
      ),
      VehicleMaintenanceGroup.differential => ('Differenziale', 'fuel_tank'),
      VehicleMaintenanceGroup.lpg => ('Impianto GPL', 'fuel_tank'),
      VehicleMaintenanceGroup.cng => ('Metano', 'fuel_tank'),
      _ => switch (kpi.type) {
        EnumPopUp.aggiornaTagliando => ('Tagliando', 'oil_pan'),
        EnumPopUp.aggiornaDistribuzione => ('Distribuzione', 'timing_belt'),
        EnumPopUp.aggiornaCambioGomme => ('Gomme', 'tire_RL'),
        EnumPopUp.pneumaticiInversione => ('Inversione', 'tire_RL'),
        EnumPopUp.revisione => ('Revisione', null),
        EnumPopUp.altro => (kpi.group?.label ?? 'Manutenzione', null),
      },
    };

    final slot = switch (kpi.group) {
      VehicleMaintenanceGroup.brakes => VehicleHeroSlot.brakes,
      VehicleMaintenanceGroup.gearbox ||
      VehicleMaintenanceGroup.differential ||
      VehicleMaintenanceGroup.lpg ||
      VehicleMaintenanceGroup.cng => VehicleHeroSlot.belowBrakes,
      _ => switch (kpi.type) {
        EnumPopUp.aggiornaTagliando => VehicleHeroSlot.lowerLeft,
        EnumPopUp.aggiornaDistribuzione => VehicleHeroSlot.upperLeft,
        _ => VehicleHeroSlot.lowerRight,
      },
    };
    final tires = kpi.type == EnumPopUp.aggiornaCambioGomme;
    return VehicleHeroCallout(
      title: title,
      anchor: anchor,
      slot: slot,
      icon: tires ? HugeIcons.strokeRoundedTire : HugeIcons.strokeRoundedTools,
      kpi: tires && rotation != null ? _tiresWithRotation(kpi, rotation) : kpi,
      rotation: tires ? rotation : null,
    );
  }

  static MaintenanceKpi _tiresWithRotation(
    MaintenanceKpi tires,
    MaintenanceKpi rotation,
  ) {
    final rows = [
      if (tires.components.isEmpty)
        MaintenanceComponentKpi(
          label: VehicleMaintenanceField.tires.label,
          percentage: tires.percentage,
          remainingKm: tires.remainingKm,
        )
      else
        ...tires.components,
      MaintenanceComponentKpi(
        label: 'Inversione',
        percentage: rotation.percentage,
        remainingKm: rotation.remainingKm,
      ),
    ];
    final values = rows.map((row) => row.percentage).whereType<double>();
    return MaintenanceKpi(
      type: tires.type,
      group: VehicleMaintenanceGroup.tires,
      remainingKm: tires.remainingKm < rotation.remainingKm
          ? tires.remainingKm
          : rotation.remainingKm,
      percentage: values.reduce((a, b) => a + b) / values.length,
      components: List.unmodifiable(rows),
    );
  }
}
