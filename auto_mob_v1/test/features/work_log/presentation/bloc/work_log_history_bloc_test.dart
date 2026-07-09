// =====================================================================
//  GOLDEN TEST — CUBIT / BLoC (layer presentation)
// ---------------------------------------------------------------------
//  Pattern per testare un Cubit/BLoC: si mocka lo use case (con mocktail)
//  e con blocTest si dichiara la SEQUENZA di stati attesa dopo un'azione.
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/vehicle_option.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/work_log_row.dart';
import 'package:auto_mob_v1/features/work_log/domain/usecases/get_vehicle_options.dart';
import 'package:auto_mob_v1/features/work_log/domain/usecases/get_vehicle_works.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_history_bloc.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_history_event.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_history_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetVehicleOptions extends Mock implements GetVehicleOptions {}

class MockGetVehicleWorks extends Mock implements GetVehicleWorks {}

void main() {
  late MockGetVehicleOptions getVehicleOptions;
  late MockGetVehicleWorks getVehicleWorks;

  const tVehicles = [
    VehicleOption(id: 'v1', targa: 'AB123CD', nome: 'Panda', brand: 'Fiat', km: 10000),
    VehicleOption(id: 'v2', targa: 'EF456GH', nome: 'Punto', brand: 'Fiat', km: 20000),
  ];

  WorkLogRow work(String id) => WorkLogRow(
        id: id,
        type: 'tagliando',
        serviceKm: 50000,
        serviceDate: DateTime(2026, 6, 16),
        hasWorkshop: true,
      );

  setUp(() {
    getVehicleOptions = MockGetVehicleOptions();
    getVehicleWorks = MockGetVehicleWorks();
  });

  WorkLogHistoryBloc buildBloc() => WorkLogHistoryBloc(
        getVehicleOptions: getVehicleOptions,
        getVehicleWorks: getVehicleWorks,
      );

  blocTest<WorkLogHistoryBloc, WorkLogHistoryState>(
    'LoadInitial: carica veicoli e prima pagina del primo veicolo',
    build: () {
      when(() => getVehicleOptions()).thenAnswer((_) async => const Right(tVehicles));
      when(() => getVehicleWorks(vehicleId: 'v1', from: 0, to: 19))
          .thenAnswer((_) async => Right([work('w1')]));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LoadInitial()),
    expect: () => [
      isA<WorkLogHistoryState>()
          .having((s) => s.status, 'status', HistoryStatus.loading),
      isA<WorkLogHistoryState>()
          .having((s) => s.status, 'status', HistoryStatus.loaded)
          .having((s) => s.vehicles, 'vehicles', tVehicles)
          .having((s) => s.selectedVehicleId, 'selectedVehicleId', 'v1')
          .having((s) => s.works.map((w) => w.id), 'works', ['w1'])
          .having((s) => s.hasReachedMax, 'hasReachedMax', true),
    ],
  );

  blocTest<WorkLogHistoryBloc, WorkLogHistoryState>(
    'LoadInitial: 0 veicoli -> loaded con liste vuote (niente crash)',
    build: () {
      when(() => getVehicleOptions()).thenAnswer((_) async => const Right([]));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LoadInitial()),
    expect: () => [
      isA<WorkLogHistoryState>()
          .having((s) => s.status, 'status', HistoryStatus.loading),
      isA<WorkLogHistoryState>()
          .having((s) => s.status, 'status', HistoryStatus.loaded)
          .having((s) => s.vehicles, 'vehicles', isEmpty)
          .having((s) => s.hasReachedMax, 'hasReachedMax', true),
    ],
    verify: (_) {
      verifyNever(() => getVehicleWorks(
            vehicleId: any(named: 'vehicleId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ));
    },
  );

  blocTest<WorkLogHistoryBloc, WorkLogHistoryState>(
    'LoadInitial: errore nel recupero veicoli -> error',
    build: () {
      when(() => getVehicleOptions())
          .thenAnswer((_) async => const Left(ServerFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LoadInitial()),
    expect: () => [
      isA<WorkLogHistoryState>()
          .having((s) => s.status, 'status', HistoryStatus.loading),
      isA<WorkLogHistoryState>()
          .having((s) => s.status, 'status', HistoryStatus.error)
          .having((s) => s.errorMessage, 'errorMessage', const ServerFailure().message),
    ],
  );

  blocTest<WorkLogHistoryBloc, WorkLogHistoryState>(
    'LoadInitial: errore nel recupero lavori -> error',
    build: () {
      when(() => getVehicleOptions()).thenAnswer((_) async => const Right(tVehicles));
      when(() => getVehicleWorks(vehicleId: 'v1', from: 0, to: 19))
          .thenAnswer((_) async => const Left(ServerFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LoadInitial()),
    expect: () => [
      isA<WorkLogHistoryState>()
          .having((s) => s.status, 'status', HistoryStatus.loading),
      isA<WorkLogHistoryState>()
          .having((s) => s.status, 'status', HistoryStatus.error),
    ],
  );

  blocTest<WorkLogHistoryBloc, WorkLogHistoryState>(
    'VehicleChanged: ricarica la pagina 0 del nuovo veicolo',
    build: () {
      when(() => getVehicleWorks(vehicleId: 'v2', from: 0, to: 19))
          .thenAnswer((_) async => Right([work('w2')]));
      return buildBloc();
    },
    seed: () => WorkLogHistoryState.initial().copyWith(
      status: HistoryStatus.loaded,
      vehicles: tVehicles,
      selectedVehicleId: 'v1',
      works: [work('w1')],
      hasReachedMax: true,
    ),
    act: (bloc) => bloc.add(const VehicleChanged('v2')),
    expect: () => [
      isA<WorkLogHistoryState>()
          .having((s) => s.selectedVehicleId, 'selectedVehicleId', 'v2')
          .having((s) => s.works, 'works', isEmpty)
          .having((s) => s.isLoadingMore, 'isLoadingMore', true),
      isA<WorkLogHistoryState>()
          .having((s) => s.works.map((w) => w.id), 'works', ['w2'])
          .having((s) => s.isLoadingMore, 'isLoadingMore', false),
    ],
  );

  blocTest<WorkLogHistoryBloc, WorkLogHistoryState>(
    'VehicleChanged: nessun cambiamento se e\' gia\' il veicolo selezionato',
    build: buildBloc,
    seed: () => WorkLogHistoryState.initial().copyWith(selectedVehicleId: 'v1'),
    act: (bloc) => bloc.add(const VehicleChanged('v1')),
    expect: () => [],
    verify: (_) {
      verifyNever(() => getVehicleWorks(
            vehicleId: any(named: 'vehicleId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ));
    },
  );

  blocTest<WorkLogHistoryBloc, WorkLogHistoryState>(
    'LoadMore: accoda la fetta successiva e aggiorna hasReachedMax',
    build: () {
      when(() => getVehicleWorks(vehicleId: 'v1', from: 1, to: 20))
          .thenAnswer((_) async => Right([work('w2')]));
      return buildBloc();
    },
    seed: () => WorkLogHistoryState.initial().copyWith(
      selectedVehicleId: 'v1',
      works: [work('w1')],
    ),
    act: (bloc) => bloc.add(const LoadMore()),
    expect: () => [
      isA<WorkLogHistoryState>()
          .having((s) => s.isLoadingMore, 'isLoadingMore', true),
      isA<WorkLogHistoryState>()
          .having((s) => s.works.map((w) => w.id), 'works', ['w1', 'w2'])
          .having((s) => s.hasReachedMax, 'hasReachedMax', true)
          .having((s) => s.isLoadingMore, 'isLoadingMore', false),
    ],
  );

  blocTest<WorkLogHistoryBloc, WorkLogHistoryState>(
    'LoadMore: non fa nulla se ha gia\' raggiunto la fine',
    build: buildBloc,
    seed: () => WorkLogHistoryState.initial().copyWith(
      selectedVehicleId: 'v1',
      hasReachedMax: true,
    ),
    act: (bloc) => bloc.add(const LoadMore()),
    expect: () => [],
    verify: (_) {
      verifyNever(() => getVehicleWorks(
            vehicleId: any(named: 'vehicleId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ));
    },
  );

  blocTest<WorkLogHistoryBloc, WorkLogHistoryState>(
    'ReloadCurrent: ricarica la pagina 0 mantenendo il veicolo selezionato',
    build: () {
      when(() => getVehicleWorks(vehicleId: 'v1', from: 0, to: 19))
          .thenAnswer((_) async => Right([work('w3')]));
      return buildBloc();
    },
    seed: () => WorkLogHistoryState.initial().copyWith(
      selectedVehicleId: 'v1',
      works: [work('w1'), work('w2')],
    ),
    act: (bloc) => bloc.add(const ReloadCurrent()),
    expect: () => [
      isA<WorkLogHistoryState>()
          .having((s) => s.works, 'works', isEmpty)
          .having((s) => s.isLoadingMore, 'isLoadingMore', true),
      isA<WorkLogHistoryState>()
          .having((s) => s.works.map((w) => w.id), 'works', ['w3'])
          .having((s) => s.isLoadingMore, 'isLoadingMore', false),
    ],
  );
}
