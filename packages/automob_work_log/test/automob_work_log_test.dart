import 'dart:async';

import 'package:automob_work_log/automob_work_log.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WorkLogEntry mantiene i dati necessari allo storico', () {
    final entry = WorkLogEntry(
      id: 'work-1',
      vehicleId: 'vehicle-1',
      type: 'tagliando',
      serviceKm: 42000,
      serviceDate: DateTime(2026, 8, 8),
    );

    expect(entry.vehicleId, 'vehicle-1');
    expect(entry.type, 'tagliando');
  });

  test(
    'i tipi aggiuntivi accettano un nome opzionale e mantengono il default',
    () {
      expect(WorkLogType.brakes.wireValue, 'freni');
      expect(WorkLogType.chassis.label, 'Telaio');
      expect(WorkLogType.gearbox.wireValue, 'cambio');
      expect(WorkLogType.battery.allowsCustomName, isTrue);
      expect(WorkLogType.tagliando.allowsCustomName, isFalse);
      expect(
        WorkLogEntry(
          id: 'work-brakes',
          vehicleId: 'vehicle-1',
          type: WorkLogType.brakes.wireValue,
          serviceKm: 1000,
          serviceDate: DateTime(2026, 8, 23),
        ).title,
        'Freni',
      );
      expect(
        WorkLogEntry(
          id: 'work-brakes-custom',
          vehicleId: 'vehicle-1',
          type: WorkLogType.brakes.wireValue,
          customName: 'Sostituzione pinze anteriori',
          serviceKm: 1000,
          serviceDate: DateTime(2026, 8, 23),
        ).title,
        'Sostituzione pinze anteriori',
      );
    },
  );

  test('il cubit conserva il nome solo per i tipi che lo supportano', () {
    final cubit = WorkLogEditorCubit(
      createWorkLog: CreateWorkLog(_WorkLogRepository()),
    );

    cubit.changeType(WorkLogType.brakes.wireValue);
    cubit.changeCustomName('Pinze anteriori');
    expect(cubit.state.customName, 'Pinze anteriori');

    cubit.changeType(WorkLogType.tagliando.wireValue);
    expect(cubit.state.customName, isEmpty);
    cubit.close();
  });

  test('il cubit preseleziona una sola categoria dal tipo intervento', () {
    final cubit = WorkLogEditorCubit(
      createWorkLog: CreateWorkLog(_WorkLogRepository()),
    );

    cubit.initialize(
      const WorkLogLaunchContext(
        vehicleId: 'vehicle-1',
        vehicleName: 'Auto',
        currentKm: 1000,
        initialWorkType: 'freni',
      ),
    );
    expect(cubit.state.partsCategory, WorkLogPartCategory.brakes);

    cubit.changeType(WorkLogType.gearbox.wireValue);
    expect(cubit.state.partsCategory, WorkLogPartCategory.gearbox);

    cubit.changePartsCategory(WorkLogPartCategory.electronics);
    expect(cubit.state.partsCategory, WorkLogPartCategory.electronics);
    cubit.changePartsCategory(WorkLogPartCategory.electronics);
    expect(cubit.state.partsCategory, isNull);
    cubit.close();
  });

  test('WorkLogLaunchContext e indipendente dal router e dal DI', () {
    const context = WorkLogLaunchContext(
      vehicleId: 'vehicle-1',
      vehicleName: 'Alfa Romeo Giulia',
      currentKm: 45500,
    );

    expect(context.initialWorkType, 'altro');
    expect(context.currentKm, 45500);
  });

  test(
    'il cubit rifiuta un lavoro con chilometri inferiori al veicolo',
    () async {
      final cubit = WorkLogEditorCubit(
        createWorkLog: CreateWorkLog(_WorkLogRepository()),
      );
      cubit.initialize(
        const WorkLogLaunchContext(
          vehicleId: 'vehicle-1',
          vehicleName: 'Auto',
          currentKm: 1000,
          initialWorkType: 'tagliando',
        ),
      );
      cubit.changeKm('999');
      await cubit.submit();

      expect(cubit.state.status, WorkLogEditorStatus.failure);
      cubit.close();
    },
  );

  test('il cubit emette successo dopo il salvataggio del repository', () async {
    final repository = _WorkLogRepository();
    final cubit = WorkLogEditorCubit(createWorkLog: CreateWorkLog(repository));
    cubit.initialize(
      const WorkLogLaunchContext(
        vehicleId: 'vehicle-1',
        vehicleName: 'Auto',
        currentKm: 1000,
        initialWorkType: 'tagliando',
      ),
    );
    cubit.changeKm('1200');
    cubit.togglePart(7);
    cubit.updatePart(
      const WorkLogPartDraft(partId: 7, quantity: 2, unitPrice: 12.50),
    );
    await cubit.submit();

    expect(cubit.state.status, WorkLogEditorStatus.success);
    expect(cubit.state.result?.vehicleId, 'vehicle-1');
    expect(cubit.state.result?.serviceKm, 1200);
    expect(repository.savedDraft?.parts.single.quantity, 2);
    expect(repository.savedDraft?.parts.single.unitPrice, 12.50);
    cubit.close();
  });

  test('il selector carica e cambia il veicolo selezionato', () async {
    final repository = _WorkLogRepository()
      ..vehicles = const [
        WorkLogVehicle(
          id: 'vehicle-1',
          name: 'Alfa Romeo Giulia',
          plate: 'AA000AA',
          currentKm: 1000,
        ),
        WorkLogVehicle(
          id: 'vehicle-2',
          name: 'Fiat Panda',
          plate: 'BB000BB',
          currentKm: 2000,
        ),
      ];
    final cubit = WorkLogVehiclesCubit(
      getWorkLogVehicles: GetWorkLogVehicles(repository),
    );

    await cubit.load();
    expect(
      (cubit.state as WorkLogVehiclesLoaded).selectedVehicleId,
      'vehicle-1',
    );

    cubit.select('vehicle-2');
    expect(
      (cubit.state as WorkLogVehiclesLoaded).selectedVehicleId,
      'vehicle-2',
    );
    await cubit.close();
  });

  test('il submit concorrente viene ignorato mentre il cubit salva', () async {
    final repository = _PendingSaveRepository();
    final cubit = WorkLogEditorCubit(createWorkLog: CreateWorkLog(repository));
    cubit.initialize(
      const WorkLogLaunchContext(
        vehicleId: 'vehicle-1',
        vehicleName: 'Auto',
        currentKm: 1000,
        initialWorkType: 'tagliando',
      ),
    );

    final first = cubit.submit();
    final second = cubit.submit();
    expect(repository.saveCalls, 1);

    repository.result.complete(right(unit));
    await Future.wait([first, second]);
    expect(cubit.state.status, WorkLogEditorStatus.success);
    await cubit.close();
  });

  test('il refresh mantiene la lista visibile durante la richiesta', () async {
    final repository = _RefreshRepository();
    final bloc = WorkLogHistoryBloc(
      getVehicleWorkHistory: GetVehicleWorkHistory(repository),
    );
    addTearDown(bloc.close);

    bloc.add(const WorkLogHistoryOpened('vehicle-1'));
    await bloc.stream.firstWhere((state) => state is WorkLogHistoryLoaded);

    bloc.add(const WorkLogHistoryRefreshRequested());
    final refreshing = await bloc.stream.firstWhere(
      (state) => state is WorkLogHistoryLoaded && state.isRefreshing,
    );
    expect((refreshing as WorkLogHistoryLoaded).entries, hasLength(1));

    repository.refresh.complete(right([repository.updatedEntry]));
    final refreshed = await bloc.stream.firstWhere(
      (state) => state is WorkLogHistoryLoaded && !state.isRefreshing,
    );
    expect((refreshed as WorkLogHistoryLoaded).entries.single.serviceKm, 1200);
  });
}

class _WorkLogRepository implements WorkLogRepository {
  WorkLogDraft? savedDraft;
  List<WorkLogVehicle> vehicles = const [];

  @override
  Future<Either<String, Unit>> createWorkLog(WorkLogDraft draft) async {
    savedDraft = draft;
    return right(unit);
  }

  @override
  Future<Either<String, List<WorkLogEntry>>> getVehicleWorks(
    String vehicleId, {
    required int from,
    required int to,
  }) async => right(const []);

  @override
  Future<Either<String, List<WorkLogVehicle>>> getVehicles() async =>
      right(vehicles);
}

class _PendingSaveRepository extends _WorkLogRepository {
  final result = Completer<Either<String, Unit>>();
  int saveCalls = 0;

  @override
  Future<Either<String, Unit>> createWorkLog(WorkLogDraft draft) {
    saveCalls++;
    return result.future;
  }
}

class _RefreshRepository extends _WorkLogRepository {
  final refresh = Completer<Either<String, List<WorkLogEntry>>>();
  int calls = 0;

  WorkLogEntry get updatedEntry => WorkLogEntry(
    id: 'work-1',
    vehicleId: 'vehicle-1',
    type: 'tagliando',
    serviceKm: 1200,
    serviceDate: DateTime(2026, 8, 12),
  );

  @override
  Future<Either<String, List<WorkLogEntry>>> getVehicleWorks(
    String vehicleId, {
    required int from,
    required int to,
  }) {
    calls++;
    if (calls > 1) return refresh.future;
    return Future.value(
      right([
        WorkLogEntry(
          id: 'work-1',
          vehicleId: vehicleId,
          type: 'tagliando',
          serviceKm: 1000,
          serviceDate: DateTime(2026, 8, 10),
        ),
      ]),
    );
  }
}
