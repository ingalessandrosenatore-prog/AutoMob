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
      return WorkshopCatalogModel.fromJson(
        response.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on PostgrestException catch (error) {
      throw WorkshopDataException(error.message, code: error.code);
    }
  }
}
