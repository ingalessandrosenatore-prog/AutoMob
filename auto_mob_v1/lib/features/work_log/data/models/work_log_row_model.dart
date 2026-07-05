import '../../domain/entities/work_log_row.dart';

/// Mapping da riga della select su `maintenance_items` (con il record padre
/// agganciato via embedding) a [WorkLogRow].
///
/// La select chiede `maintenance_records!inner(vehicle_id, mechanic_id)`,
/// quindi il record arriva ANNIDATO sotto la chiave 'maintenance_records'.
/// Da li' ricavo [hasWorkshop] (mechanic_id non null).
class WorkLogRowModel extends WorkLogRow {
  const WorkLogRowModel({
    required super.id,
    required super.type,
    super.customName,
    required super.serviceKm,
    required super.serviceDate,
    super.notes,
    required super.hasWorkshop,
  });

  factory WorkLogRowModel.fromJson(Map<String, dynamic> json) {
    // Il record padre puo' arrivare come Map (embedding 1:1).
    final record = json['maintenance_records'];
    final mechanicId =
        record is Map ? record['mechanic_id'] : null;

    return WorkLogRowModel(
      id: json['id'] as String,
      type: json['type'] as String,
      customName: json['custom_name'] as String?,
      serviceKm: (json['service_km'] as num?)?.toInt() ?? 0,
      serviceDate: DateTime.parse(json['service_date'] as String),
      notes: json['notes'] as String?,
      hasWorkshop: mechanicId != null,
    );
  }
}
