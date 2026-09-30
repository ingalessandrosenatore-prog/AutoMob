import '../../domain/entities/service_request.dart';
import '../../domain/repositories/service_request_repository.dart';
import '../datasources/service_request_remote_data_source.dart';

class ServiceRequestRepositoryImpl implements ServiceRequestRepository {
  const ServiceRequestRepositoryImpl(this.dataSource);
  final ServiceRequestRemoteDataSource dataSource;
  @override
  Future<List<ServiceRequest>> getRequests() => dataSource.getRequests();
}
