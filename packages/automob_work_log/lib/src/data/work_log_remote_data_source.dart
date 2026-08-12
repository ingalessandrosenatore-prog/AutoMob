import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/work_log_entry.dart';
import '../domain/work_log_draft.dart';
import '../domain/work_log_part.dart';
import '../domain/work_log_vehicle.dart';

abstract interface class WorkLogRemoteDataSource {
  Future<List<WorkLogVehicle>> getVehicles();
  Future<List<WorkLogEntry>> getVehicleWorks(
    String vehicleId, {
    required int from,
    required int to,
  });
  Future<void> createWorkLog(WorkLogDraft draft);
}

class SupabaseWorkLogRemoteDataSource implements WorkLogRemoteDataSource {
  const SupabaseWorkLogRemoteDataSource(this._client);
  final SupabaseClient _client;
  @override
  Future<List<WorkLogVehicle>> getVehicles() async {
    final rows = await _client
        .from('vehicles')
        .select('id, plate, brand, model, km_current')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) {
          final json = Map<String, dynamic>.from(row as Map);
          final brand = (json['brand'] as String?)?.trim() ?? '';
          final model = (json['model'] as String?)?.trim() ?? '';
          return WorkLogVehicle(
            id: json['id'] as String,
            name: [brand, model].where((value) => value.isNotEmpty).join(' '),
            plate: (json['plate'] as String?)?.trim() ?? '',
            currentKm: (json['km_current'] as num?)?.toInt() ?? 0,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<WorkLogEntry>> getVehicleWorks(
    String vehicleId, {
    required int from,
    required int to,
  }) async {
    final rows = await _client
        .from('maintenance_items')
        .select(
          'id, type, custom_name, service_km, service_date, notes, '
          'maintenance_records!inner('
          'vehicle_id, mechanic_id, mechanics(business_name)), '
          'maintenance_item_parts('
          'part_id, quantity, unit_price, notes, parts(name))',
        )
        .eq('maintenance_records.vehicle_id', vehicleId)
        .order('service_date', ascending: false)
        .order('created_at', ascending: false)
        .range(from, to);
    return (rows as List).map((row) {
      final json = Map<String, dynamic>.from(row as Map);
      final record = json['maintenance_records'];
      final mechanicId = record is Map ? record['mechanic_id'] : null;
      final mechanic = record is Map ? record['mechanics'] : null;
      final rawParts = json['maintenance_item_parts'];
      return WorkLogEntry(
        id: json['id'] as String,
        vehicleId: vehicleId,
        type: json['type'] as String,
        serviceKm: (json['service_km'] as num?)?.toInt() ?? 0,
        serviceDate: DateTime.parse(json['service_date'] as String),
        customName: json['custom_name'] as String?,
        notes: json['notes'] as String?,
        hasWorkshop: mechanicId != null,
        workshopName: mechanic is Map
            ? (mechanic['business_name'] as String?)?.trim()
            : null,
        parts: rawParts is List
            ? rawParts
                  .whereType<Map>()
                  .map(_partFromJson)
                  .toList(growable: false)
            : const [],
      );
    }).toList();
  }

  static WorkLogPart _partFromJson(Map raw) {
    final json = Map<String, dynamic>.from(raw);
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

  static double? _asDouble(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');

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

  @override
  Future<void> createWorkLog(WorkLogDraft draft) async {
    await _client.rpc(
      'crea_sessione_manutenzione',
      params: {
        'p_payload': {
          'vehicle_id': draft.vehicleId,
          'type': draft.type,
          'custom_name': draft.customName,
          'service_km': draft.serviceKm,
          'service_date': draft.serviceDate.toIso8601String().split('T').first,
          'notes': draft.notes,
          'interval_km': draft.intervalKm,
          'parts': draft.parts
              .map(
                (part) => {
                  'part_id': part.partId,
                  'quantity': part.quantity,
                  'unit_price': part.unitPrice,
                  'notes': part.notes,
                },
              )
              .toList(),
        },
      },
    );
  }
}
