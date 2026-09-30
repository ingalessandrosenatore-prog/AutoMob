// =====================================================================
//  GOLDEN TEST — CUBIT / BLoC (layer presentation)
// ---------------------------------------------------------------------
//  Pattern per testare un Cubit/BLoC: si mocka lo use case (con mocktail)
//  e con blocTest si dichiara la SEQUENZA di stati attesa dopo un'azione.
// =====================================================================

import 'dart:io';
import 'dart:async';
import 'package:auto_mob_v1/features/vehicle/domain/entities/mechanic_summary.dart';

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:auto_mob_v1/features/dashboard/domain/usecases/calculate_maintenance_cost.dart';
import 'package:auto_mob_v1/features/dashboard/domain/usecases/get_fuel_cost_for_period.dart';
import 'package:auto_mob_v1/features/dashboard/domain/entities/maintenance_cost_period.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/maintenance_kpi.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/fuel_cost_averages.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/compute_maintenance_kpis.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/get_vehicles.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/update_vehicle_photo.dart';
import 'package:auto_mob_v1/features/future_work/domain/entities/future_work_summary.dart';
import 'package:auto_mob_v1/features/future_work/domain/usecases/get_latest_open_future_works.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';

class MockGetVehicles extends Mock implements GetVehicles {}

class MockComputeMaintenanceKpis extends Mock
    implements ComputeMaintenanceKpis {}

class MockUpdateVehiclePhoto extends Mock implements UpdateVehiclePhoto {}

class MockGetLatestOpenFutureWorks extends Mock
    implements GetLatestOpenFutureWorks {}

class FakeFile extends Fake implements File {}

void main() {
  late MockGetVehicles getVehicles;
  late MockComputeMaintenanceKpis computeKpis;
  late MockUpdateVehiclePhoto updateVehiclePhoto;
  late MockGetLatestOpenFutureWorks getLatestOpenFutureWorks;

  const tKpis = <MaintenanceKpi>[];

  setUpAll(() {
    registerFallbackValue(Vehicle.placeholder());
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    getVehicles = MockGetVehicles();
    computeKpis = MockComputeMaintenanceKpis();
    updateVehiclePhoto = MockUpdateVehiclePhoto();
    getLatestOpenFutureWorks = MockGetLatestOpenFutureWorks();
    when(
      () => getLatestOpenFutureWorks(),
    ).thenAnswer((_) async => const Right([]));
  });

  DashboardBloc buildBloc() => DashboardBloc(
    getVehicles: getVehicles,
    computeKpis: computeKpis,
    updateVehiclePhoto: updateVehiclePhoto,
    calculateMaintenanceCost: const CalculateMaintenanceCost(),
    getFuelCostForPeriod: const GetFuelCostForPeriod(),
    getLatestOpenFutureWorks: getLatestOpenFutureWorks,
  );

  final tVehicle1 = vehicleFixture(id: 'v1');
  final tVehicle2 = vehicleFixture(id: 'v2');
  final tVehicle3 = vehicleFixture(id: 'v3');

  test(
    'refresh preserva officina per identità e cambio selezione durante la rete',
    () async {
      const a = MechanicSummary(id: 'a', code: 'a', businessName: 'A');
      const b = MechanicSummary(id: 'b', code: 'b', businessName: 'B');
      final vehicle = tVehicle1.copyWith(mechanics: [a, b]);
      when(() => getVehicles()).thenAnswer((_) async => Right([vehicle]));
      when(() => computeKpis(any())).thenReturn(tKpis);
      final bloc = buildBloc();
      addTearDown(bloc.close);
      final loaded = bloc.stream.firstWhere((s) => s is DashboardLoaded);
      bloc.add(LoadDashboardData());
      await loaded;
      final response = Completer<Either<Failure, List<Vehicle>>>();
      when(() => getVehicles()).thenAnswer((_) => response.future);
      final refreshing = bloc.stream.firstWhere(
        (s) => s is DashboardLoaded && s.isRefreshing,
      );
      bloc.add(DashboardRefreshRequested());
      await refreshing;
      final selected = bloc.stream.firstWhere(
        (s) =>
            s is DashboardLoaded && s.workshopIndexByVehicleId[vehicle.id] == 2,
      );
      bloc.add(WorkshopPageChanged(vehicleId: vehicle.id, index: 2));
      await selected;
      final refreshed = bloc.stream.firstWhere(
        (s) => s is DashboardLoaded && !s.isRefreshing,
      );
      response.complete(
        Right([
          vehicle.copyWith(mechanics: [b, a]),
        ]),
      );
      final result = await refreshed as DashboardLoaded;
      expect(result.workshopIndexByVehicleId[vehicle.id], 1);
    },
  );

  final tFutureWork = FutureWorkSummary(
    id: 'item-1',
    recordId: 'record-1',
    vehicleId: 'v1',
    description: 'Controllare i freni',
    registeredAt: DateTime(2026, 9, 17),
    reminderDate: DateTime(2026, 9, 30),
  );

  blocTest<DashboardBloc, DashboardState>(
    'raggruppa le segnalazioni aperte ricevute dalla query dashboard',
    build: () {
      when(
        () => getVehicles(),
      ).thenAnswer((_) async => Right([tVehicle1, tVehicle2]));
      when(
        () => getLatestOpenFutureWorks(),
      ).thenAnswer((_) async => Right([tFutureWork]));
      when(() => computeKpis(any())).thenReturn(tKpis);
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadDashboardData()),
    expect: () => [
      DashboardLoading(),
      isA<DashboardLoaded>()
          .having(
            (state) => state.selectedVehicleFutureWorks,
            'segnalazioni veicolo selezionato',
            [tFutureWork],
          )
          .having(
            (state) => state.futureWorksByVehicleId['v2'],
            'nessuna segnalazione secondo veicolo',
            isNull,
          ),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'cambia periodo e restituisce nello stato il costo manutenzione',
    build: buildBloc,
    seed: () => DashboardLoaded(
      vehicles: [vehicleFixture(maintenanceCostCents: 120000)],
      index: 0,
      kpis: const [],
      maintenanceCostCents: 10000,
    ),
    act: (bloc) =>
        bloc.add(DashboardCostPeriodChanged(MaintenanceCostPeriod.daily)),
    expect: () => [
      isA<DashboardLoaded>()
          .having(
            (state) => state.costPeriod,
            'periodo',
            MaintenanceCostPeriod.daily,
          )
          .having((state) => state.maintenanceCostCents, 'costo', 329),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'cambia periodo e restituisce nello stato il costo medio carburante',
    build: buildBloc,
    seed: () => DashboardLoaded(
      vehicles: [
        vehicleFixture(
          fuelCostAverages: const FuelCostAverages(
            dailyCents: 325,
            monthlyCents: 9891,
            annualCents: 118690,
          ),
        ),
      ],
      index: 0,
      kpis: const [],
    ),
    act: (bloc) =>
        bloc.add(DashboardCostPeriodChanged(MaintenanceCostPeriod.annual)),
    expect: () => [
      isA<DashboardLoaded>().having(
        (state) => state.fuelCostCents,
        'costo carburante',
        118690,
      ),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'emette [loading, loaded] con i veicoli e i kpi del primo quando ci sono veicoli',
    build: () {
      when(
        () => getVehicles(),
      ).thenAnswer((_) async => Right([tVehicle1, tVehicle2]));
      when(() => computeKpis(any())).thenReturn(tKpis);
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadDashboardData()),
    expect: () => [
      DashboardLoading(),
      DashboardLoaded(
        vehicles: [tVehicle1, tVehicle2],
        index: 0,
        kpis: tKpis,
        workshopMascotsByVehicleId: const {'v1': [], 'v2': []},
        workshopIndexByVehicleId: const {'v1': 0, 'v2': 0},
      ),
    ],
    verify: (_) {
      verify(() => computeKpis(tVehicle1)).called(1);
    },
  );

  blocTest<DashboardBloc, DashboardState>(
    'emette un placeholder quando la lista veicoli e\' vuota',
    build: () {
      when(() => getVehicles()).thenAnswer((_) async => const Right([]));
      when(() => computeKpis(any())).thenReturn(tKpis);
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadDashboardData()),
    expect: () => [
      DashboardLoading(),
      isA<DashboardLoaded>().having(
        (s) => s.vehicles.single.isPlaceholder,
        'isPlaceholder',
        true,
      ),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'emette [loading, error] quando il repository fallisce',
    build: () {
      when(
        () => getVehicles(),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadDashboardData()),
    expect: () => [
      DashboardLoading(),
      DashboardError(message: const ServerFailure().message),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'ricalcola i kpi del veicolo selezionato al cambio pagina',
    build: () {
      when(() => computeKpis(tVehicle2)).thenReturn(tKpis);
      return buildBloc();
    },
    seed: () => DashboardLoaded(
      vehicles: [tVehicle1, tVehicle2],
      index: 0,
      kpis: const [],
    ),
    act: (bloc) => bloc.add(DashboardPageChanged(1)),
    expect: () => [
      DashboardLoaded(vehicles: [tVehicle1, tVehicle2], index: 1, kpis: tKpis),
    ],
    verify: (_) {
      verify(() => computeKpis(tVehicle2)).called(1);
    },
  );

  blocTest<DashboardBloc, DashboardState>(
    'DashboardRefreshRequested: aggiorna i veicoli SENZA passare da DashboardLoading',
    build: () {
      when(
        () => getVehicles(),
      ).thenAnswer((_) async => Right([tVehicle1, tVehicle2]));
      when(() => computeKpis(any())).thenReturn(tKpis);
      return buildBloc();
    },
    seed: () =>
        DashboardLoaded(vehicles: [tVehicle1], index: 0, kpis: const []),
    act: (bloc) => bloc.add(DashboardRefreshRequested()),
    expect: () => [
      isA<DashboardLoaded>().having((s) => s.isRefreshing, 'isRefreshing', true)
      // i veicoli vecchi restano visibili durante il refresh.
      .having((s) => s.vehicles, 'vehicles', [tVehicle1]),
      DashboardLoaded(
        vehicles: [tVehicle1, tVehicle2],
        index: 0,
        kpis: tKpis,
        workshopMascotsByVehicleId: const {'v1': [], 'v2': []},
        workshopIndexByVehicleId: const {'v1': 0, 'v2': 0},
      ),
    ],
  );

  final refreshedVehicle2 = tVehicle2.copyWith(
    fotoPath: 'vehicle-v2-refreshed.jpg',
  );

  blocTest<DashboardBloc, DashboardState>(
    'DashboardRefreshRequested: mantiene il veicolo selezionato per id',
    build: () {
      when(() => getVehicles()).thenAnswer(
        (_) async => Right([tVehicle3, tVehicle1, refreshedVehicle2]),
      );
      when(() => computeKpis(refreshedVehicle2)).thenReturn(tKpis);
      return buildBloc();
    },
    seed: () => DashboardLoaded(
      vehicles: [tVehicle1, tVehicle2],
      index: 1,
      kpis: const [],
    ),
    act: (bloc) => bloc.add(DashboardRefreshRequested()),
    expect: () => [
      isA<DashboardLoaded>().having(
        (state) => state.isRefreshing,
        'isRefreshing',
        true,
      ),
      isA<DashboardLoaded>()
          .having((state) => state.index, 'index', 2)
          .having(
            (state) => state.vehicles[state.index].id,
            'selected vehicle id',
            tVehicle2.id,
          ),
    ],
    verify: (_) {
      verify(() => computeKpis(refreshedVehicle2)).called(1);
    },
  );

  blocTest<DashboardBloc, DashboardState>(
    'DashboardRefreshRequested: errore -> tiene i dati vecchi, spegne solo isRefreshing',
    build: () {
      when(
        () => getVehicles(),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return buildBloc();
    },
    seed: () =>
        DashboardLoaded(vehicles: [tVehicle1], index: 0, kpis: const []),
    act: (bloc) => bloc.add(DashboardRefreshRequested()),
    expect: () => [
      isA<DashboardLoaded>().having(
        (s) => s.isRefreshing,
        'isRefreshing',
        true,
      ),
      isA<DashboardLoaded>()
          .having((s) => s.isRefreshing, 'isRefreshing', false)
          .having((s) => s.vehicles, 'vehicles', [tVehicle1]),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'DashboardRefreshRequested: non fa nulla se non e\' ancora DashboardLoaded',
    build: buildBloc,
    act: (bloc) => bloc.add(DashboardRefreshRequested()),
    expect: () => [],
    verify: (_) {
      verifyNever(() => getVehicles());
    },
  );

  final tFoto = File('veicolo_v1.jpg');

  // Dopo il cambio foto il veicolo torna dal reload con un fotoPath nuovo:
  // la lista ricaricata differisce dal seed (altrimenti Bloc non riemette).
  final tVehicle2Foto = tVehicle2.copyWith(fotoPath: 'foto_nuova.jpg');

  blocTest<DashboardBloc, DashboardState>(
    'foto ok: ricarica SENZA DashboardLoading e preserva l\'indice selezionato',
    build: () {
      when(
        () => updateVehiclePhoto(targa: 'v1', foto: tFoto),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => getVehicles(),
      ).thenAnswer((_) async => Right([tVehicle1, tVehicle2Foto]));
      when(() => computeKpis(any())).thenReturn(tKpis);
      return buildBloc();
    },
    // Stavo guardando il 2o veicolo (index 1): dopo il cambio foto deve restare li'.
    seed: () => DashboardLoaded(
      vehicles: [tVehicle1, tVehicle2],
      index: 1,
      kpis: const [],
    ),
    act: (bloc) =>
        bloc.add(VehiclePhotoUpdateRequested(targa: 'v1', foto: tFoto)),
    expect: () => [
      // Niente DashboardLoading: il carosello non viene mai smontato.
      DashboardLoaded(
        vehicles: [tVehicle1, tVehicle2Foto],
        workshopMascotsByVehicleId: const {'v1': [], 'v2': []},
        workshopIndexByVehicleId: const {'v1': 0, 'v2': 0},
        index: 1,
        kpis: tKpis,
      ),
    ],
    verify: (_) {
      verify(() => updateVehiclePhoto(targa: 'v1', foto: tFoto)).called(1);
      // KPI ricalcolati per il veicolo all'indice preservato (il 2o).
      verify(() => computeKpis(tVehicle2Foto)).called(1);
    },
  );

  blocTest<DashboardBloc, DashboardState>(
    'foto in errore: emette DashboardLoaded con photoUpdateError e NON ricarica',
    build: () {
      when(
        () => updateVehiclePhoto(targa: 'v1', foto: tFoto),
      ).thenAnswer((_) async => const Left(StorageFailure()));
      return buildBloc();
    },
    seed: () =>
        DashboardLoaded(vehicles: [tVehicle1], index: 0, kpis: const []),
    act: (bloc) =>
        bloc.add(VehiclePhotoUpdateRequested(targa: 'v1', foto: tFoto)),
    expect: () => [
      isA<DashboardLoaded>()
          .having(
            (s) => s.photoUpdateError,
            'photoUpdateError',
            const StorageFailure().message,
          )
          .having((s) => s.vehicles, 'vehicles', [tVehicle1]),
    ],
    verify: (_) {
      verifyNever(() => getVehicles());
    },
  );

  blocTest<DashboardBloc, DashboardState>(
    'foto: ignora l\'evento se lo stato non e\' ancora DashboardLoaded',
    build: buildBloc,
    act: (bloc) =>
        bloc.add(VehiclePhotoUpdateRequested(targa: 'v1', foto: tFoto)),
    expect: () => [],
    verify: (_) {
      verifyNever(
        () => updateVehiclePhoto(
          targa: any(named: 'targa'),
          foto: any(named: 'foto'),
        ),
      );
    },
  );
}
