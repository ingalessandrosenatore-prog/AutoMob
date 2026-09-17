import '../entities/service_request.dart';
import '../repositories/service_request_repository.dart';

class GetServiceRequests {
  const GetServiceRequests(this.repository);
  final ServiceRequestRepository repository;
  Future<List<ServiceRequest>> call() => repository.getRequests();
}
