import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_exception.dart';
import '../models/workshop_catalog_model.dart';

abstract interface class WorkshopRemoteDataSource {
  Future<WorkshopCatalogModel> getCatalog();
}

final class SupabaseWorkshopRemoteDataSource
    implements WorkshopRemoteDataSource {
  const SupabaseWorkshopRemoteDataSource(this.client);

  final SupabaseClient client;

  @override
  Future<WorkshopCatalogModel> getCatalog() async {
    try {
      final response = await client.rpc('get_mechanic_home_catalog');
      if (response is! Map) {
        throw const WorkshopDataException('Risposta catalogo non valida.');
      }
      final json = response.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final reportsByVehicleId = await _fetchReportsByVehicleId();
      if (reportsByVehicleId.isNotEmpty && json['vehicles'] is List) {
        json['vehicles'] = (json['vehicles'] as List)
            .map((item) {
              if (item is! Map) return item;
              final vehicleMap = item.map(
                (key, value) => MapEntry(key.toString(), value),
              );
              final vehicleId = vehicleMap['id']?.toString();
              if (vehicleId != null &&
                  vehicleMap['reports'] == null &&
                  reportsByVehicleId.containsKey(vehicleId)) {
                vehicleMap['reports'] = reportsByVehicleId[vehicleId];
              }
              return vehicleMap;
            })
            .toList(growable: false);
      }
      return WorkshopCatalogModel.fromJson(json);
    } on PostgrestException catch (error) {
      throw WorkshopDataException(error.message, code: error.code);
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>>
  _fetchReportsByVehicleId() async {
    try {
      final response = await client.rpc('get_mechanic_future_work_catalog');
      if (response is! List) return const {};
      final result = <String, List<Map<String, dynamic>>>{};
      for (final raw in response) {
        if (raw is! Map) continue;
        final row = raw.map((key, value) => MapEntry(key.toString(), value));
        final vehicleId = (row['id'] ?? row['vehicle_id'])?.toString();
        final rawReports = row['reports'];
        if (vehicleId == null || rawReports is! List) continue;
        final fallbackDate = row['registered_at'];
        result[vehicleId] = rawReports
            .whereType<Map>()
            .map((report) {
              final reportMap = report.map(
                (key, value) => MapEntry(key.toString(), value),
              );
              reportMap['registered_at'] ??= fallbackDate;
              return reportMap;
            })
            .toList(growable: false);
      }
      return result;
    } catch (_) {
      return const {};
    }
  }
}
