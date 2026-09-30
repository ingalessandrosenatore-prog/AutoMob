import '../entities/service_request.dart';

abstract interface class ServiceRequestRepository {
  Future<List<ServiceRequest>> getRequests();
}
