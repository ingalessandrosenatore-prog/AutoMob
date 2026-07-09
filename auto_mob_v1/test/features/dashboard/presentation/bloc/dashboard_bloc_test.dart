// =====================================================================
//  GOLDEN TEST — CUBIT / BLoC (layer presentation)
// ---------------------------------------------------------------------
//  Pattern per testare un Cubit/BLoC: si mocka lo use case (con mocktail)
//  e con blocTest si dichiara la SEQUENZA di stati attesa dopo un'azione.
// =====================================================================

import 'dart:io';

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/maintenance_kpi.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/compute_maintenance_kpis.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/get_vehicles.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/update_vehicle_photo.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';

class MockGetVehicles extends Mock implements GetVehicles {}

class MockComputeMaintenanceKpis extends Mock implements ComputeMaintenanceKpis {}

class MockUpdateVehiclePhoto extends Mock implements UpdateVehiclePhoto {}

class FakeFile extends Fake implements File {}

void main() {
  late MockGetVehicles getVehicles;
  late MockComputeMaintenanceKpis computeKpis;
  late MockUpdateVehiclePhoto updateVehiclePhoto;

  const tKpis = <MaintenanceKpi>[];

  setUpAll(() {
    registerFallbackValue(Vehicle.placeholder());
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    getVehicles = MockGetVehicles();
    computeKpis = MockComputeMaintenanceKpis();
    updateVehiclePhoto = MockUpdateVehiclePhoto();
  });

  DashboardBloc buildBloc() => DashboardBloc(
        getVehicles: getVehicles,
        computeKpis: computeKpis,
        updateVehiclePhoto: updateVehiclePhoto,
      );

  final tVehicle1 = vehicleFixture(id: 'v1');
  final tVehicle2 = vehicleFixture(id: 'v2');

  blocTest<DashboardBloc, DashboardState>(
    'emette [loading, loaded] con i veicoli e i kpi del primo quando ci sono veicoli',
    build: () {
      when(() => getVehicles())
          .thenAnswer((_) async => Right([tVehicle1, tVehicle2]));
      when(() => computeKpis(any())).thenReturn(tKpis);
      return buildBloc();
    },
    act: (bloc) => bloc.add(LoadDashboardData()),
    expect: () => [
      DashboardLoading(),
      DashboardLoaded(vehicles: [tVehicle1, tVehicle2], index: 0, kpis: tKpis),
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
      isA<DashboardLoaded>()
          .having((s) => s.vehicles.single.isPlaceholder, 'isPlaceholder', true),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'emette [loading, error] quando il repository fallisce',
    build: () {
      when(() => getVehicles())
          .thenAnswer((_) async => const Left(ServerFailure()));
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

  final tFoto = File('veicolo_v1.jpg');

  blocTest<DashboardBloc, DashboardState>(
    'ricarica la dashboard quando la foto viene aggiornata con successo',
    build: () {
      when(() => updateVehiclePhoto(targa: 'v1', foto: tFoto))
          .thenAnswer((_) async => const Right(null));
      when(() => getVehicles())
          .thenAnswer((_) async => Right([tVehicle1, tVehicle2]));
      when(() => computeKpis(any())).thenReturn(tKpis);
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      VehiclePhotoUpdateRequested(targa: 'v1', foto: tFoto),
    ),
    expect: () => [
      DashboardLoading(),
      DashboardLoaded(vehicles: [tVehicle1, tVehicle2], index: 0, kpis: tKpis),
    ],
    verify: (_) {
      verify(() => updateVehiclePhoto(targa: 'v1', foto: tFoto)).called(1);
    },
  );

  blocTest<DashboardBloc, DashboardState>(
    'non ricarica la dashboard quando l\'aggiornamento foto fallisce',
    build: () {
      when(() => updateVehiclePhoto(targa: 'v1', foto: tFoto))
          .thenAnswer((_) async => const Left(StorageFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      VehiclePhotoUpdateRequested(targa: 'v1', foto: tFoto),
    ),
    expect: () => [],
    verify: (_) {
      verifyNever(() => getVehicles());
    },
  );
}
