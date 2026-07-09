// =====================================================================
//  GOLDEN TEST — CUBIT / BLoC (layer presentation)
// ---------------------------------------------------------------------
//  Pattern per testare un Cubit/BLoC: si mocka lo use case (con mocktail)
//  e con blocTest si dichiara la SEQUENZA di stati attesa dopo un'azione.
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_draft.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/save_draft_step.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/save_vehicle.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/add_vehicle_bloc.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/add_vehicle_event.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/add_vehicle_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSaveDraftStep extends Mock implements SaveDraftStep {}

class MockSaveVehicle extends Mock implements SaveVehicle {}

void main() {
  late MockSaveDraftStep saveDraftStep;
  late MockSaveVehicle saveVehicle;

  setUpAll(() {
    registerFallbackValue(const VehicleDraft());
  });

  setUp(() {
    saveDraftStep = MockSaveDraftStep();
    saveVehicle = MockSaveVehicle();
  });

  AddVehicleBloc buildBloc() =>
      AddVehicleBloc(saveDraftStep: saveDraftStep, saveVehicle: saveVehicle);

  blocTest<AddVehicleBloc, AddVehicleState>(
    'Step1Submitted: salva il draft e avanza allo step successivo',
    build: () {
      when(() => saveDraftStep(any())).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    act: (bloc) => bloc.add(Step1Submitted(
      marca: 'Fiat',
      modello: 'Panda',
      year: 2020,
      carburante: 'benzina',
      targa: 'AB123CD',
    )),
    expect: () => [
      isA<AddVehicleState>()
          .having((s) => s.status, 'status', AddVehicleStatus.loading),
      isA<AddVehicleState>()
          .having((s) => s.status, 'status', AddVehicleStatus.idle)
          .having((s) => s.currentStep, 'currentStep', 1),
    ],
  );

  blocTest<AddVehicleBloc, AddVehicleState>(
    'Step1Submitted: emette errore quando il salvataggio del draft fallisce',
    build: () {
      when(() => saveDraftStep(any()))
          .thenAnswer((_) async => const Left(StorageFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(Step1Submitted(
      marca: 'Fiat',
      modello: 'Panda',
      year: 2020,
      carburante: 'benzina',
      targa: 'AB123CD',
    )),
    expect: () => [
      isA<AddVehicleState>()
          .having((s) => s.status, 'status', AddVehicleStatus.loading),
      isA<AddVehicleState>()
          .having((s) => s.status, 'status', AddVehicleStatus.error)
          .having((s) => s.errorMessage, 'errorMessage', isNotNull)
          .having((s) => s.currentStep, 'currentStep', 0),
    ],
  );

  blocTest<AddVehicleBloc, AddVehicleState>(
    'SaveWizard: persiste il draft e salva il veicolo -> completed',
    build: () {
      when(() => saveDraftStep(any())).thenAnswer((_) async => const Right(null));
      when(() => saveVehicle(any())).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    act: (bloc) => bloc.add(SaveWizard()),
    expect: () => [
      isA<AddVehicleState>()
          .having((s) => s.status, 'status', AddVehicleStatus.loading),
      isA<AddVehicleState>()
          .having((s) => s.status, 'status', AddVehicleStatus.completed),
    ],
    verify: (_) {
      verify(() => saveDraftStep(any())).called(1);
      verify(() => saveVehicle(any())).called(1);
    },
  );

  blocTest<AddVehicleBloc, AddVehicleState>(
    'SaveWizard: se il draft non si salva NON chiama saveVehicle',
    build: () {
      when(() => saveDraftStep(any()))
          .thenAnswer((_) async => const Left(StorageFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(SaveWizard()),
    expect: () => [
      isA<AddVehicleState>()
          .having((s) => s.status, 'status', AddVehicleStatus.loading),
      isA<AddVehicleState>()
          .having((s) => s.status, 'status', AddVehicleStatus.error),
    ],
    verify: (_) {
      verifyNever(() => saveVehicle(any()));
    },
  );

  blocTest<AddVehicleBloc, AddVehicleState>(
    'SaveWizard: draft ok ma saveVehicle fallisce -> error',
    build: () {
      when(() => saveDraftStep(any())).thenAnswer((_) async => const Right(null));
      when(() => saveVehicle(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(SaveWizard()),
    expect: () => [
      isA<AddVehicleState>()
          .having((s) => s.status, 'status', AddVehicleStatus.loading),
      isA<AddVehicleState>()
          .having((s) => s.status, 'status', AddVehicleStatus.error)
          .having((s) => s.errorMessage, 'errorMessage', const ServerFailure().message),
    ],
  );

  blocTest<AddVehicleBloc, AddVehicleState>(
    'StepBackPressed: torna allo step precedente',
    build: buildBloc,
    seed: () => const AddVehicleState(currentStep: 2),
    act: (bloc) => bloc.add(StepBackPressed()),
    expect: () => [
      const AddVehicleState(currentStep: 1),
    ],
  );

  blocTest<AddVehicleBloc, AddVehicleState>(
    'AddVehicleStarted: riporta il wizard allo step 0',
    build: buildBloc,
    seed: () => const AddVehicleState(currentStep: 3),
    act: (bloc) => bloc.add(AddVehicleStarted()),
    expect: () => [
      const AddVehicleState(currentStep: 0),
    ],
  );
}
