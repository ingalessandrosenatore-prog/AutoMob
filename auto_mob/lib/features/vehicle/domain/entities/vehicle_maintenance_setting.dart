import 'package:equatable/equatable.dart';

enum VehicleMaintenanceGroup {
  service('Tagliando'),
  brakes('Freni'),
  gearbox('Trasmissione'),
  differential('Differenziale'),
  engine('Motore'),
  lpg('Impianto GPL'),
  cng('Metano'),
  distribution('Distribuzione'),
  tires('Cambio gomme');

  const VehicleMaintenanceGroup(this.label);
  final String label;

  String get workType => switch (this) {
    service => 'tagliando',
    brakes => 'freni',
    gearbox || differential => 'cambio',
    engine => 'motore',
    lpg || cng => 'altro',
    distribution => 'distribuzione',
    tires => 'pneumatici_cambio',
  };
}

enum VehicleMaintenanceField {
  oil('Olio motore e filtro olio', [15, 200], 15000, years: 1),
  air('Filtro aria', [16], 15000),
  cabin('Filtro antipolline', [17], 15000),
  fuel('Filtro carburante', [18], 30000),
  pads('Pastiglie', [20, 21], 40000, separateReference: true),
  brakeFluid('Liquido freni', [26], 100000, separateReference: true),
  sparkPlugs('Candele', [7], 60000, separateReference: true),
  gearbox('Olio cambio', [201], 80000, separateReference: true),
  differential('Olio differenziale', [202], 80000, optional: true),
  lpgFilter('Filtro GPL', [203], 30000, optional: true, fuelType: 'gpl'),
  lpgTank(
    'Serbatoio GPL',
    [204],
    null,
    years: 10,
    optional: true,
    fuelType: 'gpl',
  ),
  cngTank(
    'Bombole metano',
    [205],
    null,
    years: 4,
    optional: true,
    fuelType: 'metano',
  ),
  distribution('Kit distribuzione e cuscinetti', [206], 100000),
  tires('Pneumatici', [86], 40000);

  const VehicleMaintenanceField(
    this.label,
    this.partIds,
    this.km, {
    this.years,
    this.optional = false,
    this.separateReference = false,
    this.fuelType,
  });

  final String label;
  final List<int> partIds;
  final int? km;
  final int? years;
  final bool optional;
  final bool separateReference;
  final String? fuelType;

  VehicleMaintenanceGroup get group => switch (this) {
    oil || air || cabin || fuel => VehicleMaintenanceGroup.service,
    pads || brakeFluid => VehicleMaintenanceGroup.brakes,
    sparkPlugs => VehicleMaintenanceGroup.engine,
    gearbox => VehicleMaintenanceGroup.gearbox,
    differential => VehicleMaintenanceGroup.differential,
    lpgFilter || lpgTank => VehicleMaintenanceGroup.lpg,
    cngTank => VehicleMaintenanceGroup.cng,
    distribution => VehicleMaintenanceGroup.distribution,
    tires => VehicleMaintenanceGroup.tires,
  };

  bool appliesTo(String? fuel) {
    final normalized = fuel?.toLowerCase() ?? '';
    return switch (fuelType) {
      'gpl' => normalized.contains('gpl'),
      'metano' => normalized.contains('metano') || normalized.contains('cng'),
      _ => true,
    };
  }
}

class VehicleMaintenanceSetting extends Equatable {
  const VehicleMaintenanceSetting({
    required this.field,
    this.intervalKm,
    this.intervalYears,
    this.lastKm,
    this.lastDate,
  });

  final VehicleMaintenanceField field;
  final int? intervalKm;
  final int? intervalYears;
  final int? lastKm;
  final DateTime? lastDate;

  @override
  List<Object?> get props => [
    field,
    intervalKm,
    intervalYears,
    lastKm,
    lastDate,
  ];
}
