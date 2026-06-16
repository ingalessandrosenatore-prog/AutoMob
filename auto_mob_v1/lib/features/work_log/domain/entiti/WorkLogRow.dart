import 'package:equatable/equatable.dart';

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

  const WorkLogRow({
    required this.id,
    required this.type,
    this.customName,
    required this.serviceKm,
    required this.serviceDate,
    this.notes,
    required this.hasWorkshop,
  });

  @override
  List<Object?> get props =>
      [id, type, customName, serviceKm, serviceDate, notes, hasWorkshop];
}
