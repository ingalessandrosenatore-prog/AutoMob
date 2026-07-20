import 'package:equatable/equatable.dart';

import 'work_log_part.dart';

/// Una riga dello storico lavori = un `maintenance_item`.
/// Il [type] e' l'enum testuale del DB; [customName] e' valorizzato solo
/// per type='altro'. [hasWorkshop] = lavoro svolto in officina
/// (record con mechanic_id non null). La mappatura type -> etichetta e la
/// formattazione (data, km) restano nella presentation.
class WorkLogRow extends Equatable {
  final String id;
  final String type;
  final String? customName;
  final int serviceKm;
  final DateTime serviceDate;
  final String? notes;
  final bool hasWorkshop;
  final String? workshopName;
  final List<WorkLogPart> parts;

  const WorkLogRow({
    required this.id,
    required this.type,
    this.customName,
    required this.serviceKm,
    required this.serviceDate,
    this.notes,
    required this.hasWorkshop,
    this.workshopName,
    this.parts = const [],
  });

  /// Totale dei soli ricambi che hanno un prezzo valorizzato.
  int get partsTotalCents =>
      parts.fold(0, (total, part) => total + (part.subtotalCents ?? 0));

  @override
  List<Object?> get props => [
    id,
    type,
    customName,
    serviceKm,
    serviceDate,
    notes,
    hasWorkshop,
    workshopName,
    parts,
  ];
}
