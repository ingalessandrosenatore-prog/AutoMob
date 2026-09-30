import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_exception.dart';
import '../models/workshop_overview_catalog_model.dart';

abstract interface class WorkshopOverviewRemoteDataSource {
  Future<WorkshopOverviewCatalogModel> getOverview(DateTime referenceDate);
}

class SupabaseWorkshopOverviewRemoteDataSource
    implements WorkshopOverviewRemoteDataSource {
  const SupabaseWorkshopOverviewRemoteDataSource(this.client);

  final SupabaseClient client;

  @override
  Future<WorkshopOverviewCatalogModel> getOverview(
    DateTime referenceDate,
  ) async {
    try {
      final date = referenceDate.toIso8601String().split('T').first;
      final response = await client.rpc(
        'get_mechanic_workshop_overview',
        params: {'p_reference_date': date},
      );
      if (response is! Map) {
        throw const WorkshopDataException('Risposta KPI non valida.');
      }
      return WorkshopOverviewCatalogModel.fromJson(
        response.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on PostgrestException catch (error) {
      throw WorkshopDataException(error.message, code: error.code);
    } on FormatException catch (error) {
      throw WorkshopDataException(error.message);
    }
  }
}
