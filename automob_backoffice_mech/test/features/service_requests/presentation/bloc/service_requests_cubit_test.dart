import 'dart:async';
import 'package:automob_backoffice_mech/features/service_requests/domain/entities/service_request.dart';
import 'package:automob_backoffice_mech/features/service_requests/domain/repositories/service_request_repository.dart';
import 'package:automob_backoffice_mech/features/service_requests/domain/usecases/get_service_requests.dart';
import 'package:automob_backoffice_mech/features/service_requests/presentation/bloc/service_requests_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'carica oltre 20 risultati con una query e refresh sostituisce tutto',
    () async {
      final repository = _Repository();
      final cubit = ServiceRequestsCubit(GetServiceRequests(repository));
      addTearDown(cubit.close);
      await cubit.load();
      expect((cubit.state as ServiceRequestsReady).requests, hasLength(45));
      expect(repository.calls, 1);
      repository.count = 2;
      await cubit.refresh();
      expect((cubit.state as ServiceRequestsReady).requests, hasLength(2));
      expect(repository.calls, 2);
    },
  );
  test(
    'accorpa richieste concorrenti e tollera chiusura durante caricamento',
    () async {
      final repository = _Repository()..pending = Completer<void>();
      final cubit = ServiceRequestsCubit(GetServiceRequests(repository));
      final first = cubit.load();
      final second = cubit.refresh();
      expect(repository.calls, 1);
      await cubit.close();
      repository.pending!.complete();
      await Future.wait([first, second]);
    },
  );
  test('filtra per veicolo targa e descrizione del problema', () async {
    final cubit = ServiceRequestsCubit(GetServiceRequests(_SearchRepository()));
    addTearDown(cubit.close);
    await cubit.load();

    cubit.search('alfa mito');
    expect(
      (cubit.state as ServiceRequestsReady).requests.single.id,
      'request-alfa',
    );

    cubit.search('EF 456 GH');
    expect(
      (cubit.state as ServiceRequestsReady).requests.single.id,
      'request-fiat',
    );

    cubit.search('rumore motore');
    final state = cubit.state as ServiceRequestsReady;
    expect(state.requests.single.id, 'request-alfa');
    expect(state.query, 'rumore motore');

    cubit.search('');
    expect((cubit.state as ServiceRequestsReady).requests, hasLength(2));
  });
}

class _Repository implements ServiceRequestRepository {
  int calls = 0;
  int count = 45;
  Completer<void>? pending;
  @override
  Future<List<ServiceRequest>> getRequests() async {
    calls++;
    if (pending != null) await pending!.future;
    return List.generate(
      count,
      (i) => ServiceRequest(
        id: 'request-$i',
        vehicleModel: 'Veicolo $i',
        plate: 'AA123BB',
        issues: const ['Controllo'],
        registeredAt: DateTime(2026, 9, 1),
        reminderDate: DateTime(2026, 9, 30),
      ),
    );
  }
}

class _SearchRepository implements ServiceRequestRepository {
  @override
  Future<List<ServiceRequest>> getRequests() async => [
    ServiceRequest(
      id: 'request-alfa',
      vehicleModel: 'Alfa Romeo Mito',
      plate: 'DT 512 FD',
      issues: const ['Rumore anomalo dal motore'],
      registeredAt: DateTime(2026, 9, 1),
      reminderDate: DateTime(2026, 9, 30),
    ),
    ServiceRequest(
      id: 'request-fiat',
      vehicleModel: 'Fiat Panda',
      plate: 'EF 456 GH',
      issues: const ['Cambio pastiglie'],
      registeredAt: DateTime(2026, 9, 2),
      reminderDate: DateTime(2026, 10, 1),
    ),
  ];
}
