import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/service_request.dart';
import '../models/service_request_model.dart';

abstract interface class ServiceRequestRemoteDataSource {
  Future<List<ServiceRequest>> getRequests();
}

class SupabaseServiceRequestRemoteDataSource
    implements ServiceRequestRemoteDataSource {
  const SupabaseServiceRequestRemoteDataSource(this.client);
  final SupabaseClient client;
  @override
  Future<List<ServiceRequest>> getRequests() async {
    // A scalar JSON result avoids the Data API row cap truncating the catalog.
    final response = await client.rpc('get_mechanic_future_work_catalog');
    return (response as List)
        .map(
          (row) => ServiceRequestModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }
}
