import '../../domain/entities/work_log_part.dart';
import '../../domain/entities/work_log_row.dart';

/// Mapping da riga della select su `maintenance_items` (con record padre e
/// ricambi agganciati via embedding) a [WorkLogRow].
class WorkLogRowModel extends WorkLogRow {
  const WorkLogRowModel({
    required super.id,
    required super.type,
    super.customName,
    required super.serviceKm,
    required super.serviceDate,
    super.notes,
    required super.hasWorkshop,
    super.workshopName,
    super.parts,
  });

  factory WorkLogRowModel.fromJson(Map<String, dynamic> json) {
    final record = json['maintenance_records'];
    final mechanicId = record is Map ? record['mechanic_id'] : null;
    final mechanic = record is Map ? record['mechanics'] : null;
    final workshopName = mechanic is Map
        ? (mechanic['business_name'] as String?)?.trim()
        : null;
    final rawParts = json['maintenance_item_parts'];
    final parts = rawParts is List
        ? rawParts
              .whereType<Map>()
              .map((part) => _partFromJson(Map<String, dynamic>.from(part)))
              .toList(growable: false)
        : const <WorkLogPart>[];

    return WorkLogRowModel(
      id: json['id'] as String,
      type: json['type'] as String,
      customName: json['custom_name'] as String?,
      serviceKm: (json['service_km'] as num?)?.toInt() ?? 0,
      serviceDate: DateTime.parse(json['service_date'] as String),
      notes: json['notes'] as String?,
      hasWorkshop: mechanicId != null,
      workshopName: workshopName?.isNotEmpty == true ? workshopName : null,
      parts: parts,
    );
  }

  static WorkLogPart _partFromJson(Map<String, dynamic> json) {
    final catalogPart = json['parts'];
    final name = catalogPart is Map
        ? (catalogPart['name'] as String?)?.trim() ?? ''
        : '';

    return WorkLogPart(
      partId: (json['part_id'] as num).toInt(),
      name: name.isEmpty ? 'Ricambio' : name,
      quantity: _asDouble(json['quantity']) ?? 1,
      unitPriceCents: _priceToCents(json['unit_price']),
      notes: (json['notes'] as String?)?.trim(),
    );
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _priceToCents(Object? value) {
    final raw = value?.toString().trim() ?? '';
    final match = RegExp(r'^(-?)(\d+)(?:\.(\d+))?$').firstMatch(raw);
    if (match == null) return null;

    final sign = match.group(1) == '-' ? -1 : 1;
    final whole = int.parse(match.group(2)!);
    final decimals = (match.group(3) ?? '').padRight(3, '0');
    var cents = whole * 100 + int.parse(decimals.substring(0, 2));
    if (int.parse(decimals.substring(2, 3)) >= 5) cents++;
    return sign * cents;
  }
}
