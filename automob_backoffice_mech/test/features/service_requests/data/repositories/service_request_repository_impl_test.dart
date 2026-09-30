import 'package:automob_backoffice_mech/features/service_requests/data/repositories/service_request_repository_impl.dart';
import 'package:automob_backoffice_mech/features/service_requests/data/datasources/service_request_remote_data_source.dart';
import 'package:automob_backoffice_mech/features/service_requests/domain/entities/service_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'propaga errori della sorgente senza trasformarli in lista vuota',
    () async {
      final repository = ServiceRequestRepositoryImpl(_FailingSource());
      await expectLater(repository.getRequests(), throwsStateError);
    },
  );
}

class _FailingSource implements ServiceRequestRemoteDataSource {
  @override
  Future<List<ServiceRequest>> getRequests() async =>
      throw StateError('offline');
}
