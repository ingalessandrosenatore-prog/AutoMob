import 'package:equatable/equatable.dart';

import 'work_log_part.dart';

class WorkLogEntry extends Equatable {
  const WorkLogEntry({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.serviceKm,
    required this.serviceDate,
    this.customName,
    this.notes,
    this.hasWorkshop = false,
    this.workshopName,
    this.parts = const [],
  });
  final String id;
  final String vehicleId;
  final String type;
  final int serviceKm;
  final DateTime serviceDate;
  final String? customName;
  final String? notes;
  final bool hasWorkshop;
  final String? workshopName;
  final List<WorkLogPart> parts;

  String get title =>
      type == 'altro' && (customName?.trim().isNotEmpty ?? false)
      ? customName!.trim()
      : switch (type) {
          'tagliando' => 'Tagliando',
          'distribuzione' => 'Distribuzione',
          'revisione' => 'Revisione',
          'pneumatici_cambio' => 'Cambio gomme',
          'pneumatici_inversione' => 'Inversione gomme',
          _ => type,
        };

  int get partsTotalCents =>
      parts.fold(0, (total, part) => total + (part.subtotalCents ?? 0));
  @override
  List<Object?> get props => [
    id,
    vehicleId,
    type,
    serviceKm,
    serviceDate,
    customName,
    notes,
    hasWorkshop,
    workshopName,
    parts,
  ];
}
