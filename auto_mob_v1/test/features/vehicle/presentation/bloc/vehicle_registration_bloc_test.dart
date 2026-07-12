// =====================================================================
//  GOLDEN TEST — BLoC (layer presentation)
// ---------------------------------------------------------------------
//  Pattern per testare un BLoC: si mocka lo use case (con mocktail)
//  e con blocTest si dichiara la SEQUENZA di stati attesa dopo un'azione.
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_lookup_result.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/lookup_vehicle_by_plate.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/vehicle_registration_bloc.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/vehicle_registration_event.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/vehicle_registration_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLookupVehicleByPlate extends Mock implements LookupVehicleByPlate {}

void main() {
  late MockLookupVehicleByPlate lookupVehicleByPlate;

  setUp(() {
    lookupVehicleByPlate = MockLookupVehicleByPlate();
  });

  VehicleRegistrationBloc buildBloc() =>
      VehicleRegistrationBloc(lookupVehicleByPlate: lookupVehicleByPlate);

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'MechanicStepSubmitted: salva il codice meccanico e avanza allo step 1',
    build: buildBloc,
    act: (bloc) => bloc.add(MechanicStepSubmitted(codiceMeccanico: 'MEC001')),
    expect: () => [
      isA<VehicleRegistrationState>()
          .having((s) => s.currentStep, 'currentStep', 1)
          .having((s) => s.draft.codiceMeccanico, 'codiceMeccanico', 'MEC001'),
    ],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'PlateSubmitted: veicolo trovato -> merge dati e lookupStatus success',
    build: () {
      when(() => lookupVehicleByPlate('AB123CD')).thenAnswer(
        (_) async => const Right(
          VehicleLookupResult(
            marca: 'Fiat',
            modello: 'Panda',
            anno: 2019,
            carburante: 'Benzina',
            cilindrata: 1242,
          ),
        ),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(PlateSubmitted(targa: 'AB123CD')),
    expect: () => [
      isA<VehicleRegistrationState>()
          .having(
            (s) => s.lookupStatus,
            'lookupStatus',
            RegistrationLookupStatus.loading,
          )
          .having((s) => s.draft.targa, 'targa', 'AB123CD'),
      isA<VehicleRegistrationState>()
          .having(
            (s) => s.lookupStatus,
            'lookupStatus',
            RegistrationLookupStatus.success,
          )
          .having((s) => s.currentStep, 'currentStep', 1)
          .having((s) => s.draft.marca, 'marca', 'Fiat')
          .having((s) => s.draft.modello, 'modello', 'Panda')
          .having((s) => s.draft.cilindrata, 'cilindrata', 1242),
    ],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'PlateSubmitted: veicolo non trovato -> lookupStatus notFound ma avanza comunque',
    build: () {
      when(
        () => lookupVehicleByPlate('FAIL123'),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(PlateSubmitted(targa: 'FAIL123')),
    expect: () => [
      isA<VehicleRegistrationState>().having(
        (s) => s.lookupStatus,
        'lookupStatus',
        RegistrationLookupStatus.loading,
      ),
      isA<VehicleRegistrationState>()
          .having(
            (s) => s.lookupStatus,
            'lookupStatus',
            RegistrationLookupStatus.notFound,
          )
          .having((s) => s.currentStep, 'currentStep', 1)
          .having((s) => s.draft.marca, 'marca', isNull),
    ],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'VerifyStepSubmitted: aggiorna i dati corretti a mano e avanza',
    build: buildBloc,
    seed: () => const VehicleRegistrationState(currentStep: 2),
    act: (bloc) => bloc.add(
      VerifyStepSubmitted(
        marca: 'Toyota',
        modello: 'Yaris',
        anno: 2021,
        carburante: 'Ibrida',
        cilindrata: 1490,
      ),
    ),
    expect: () => [
      isA<VehicleRegistrationState>()
          .having((s) => s.currentStep, 'currentStep', 3)
          .having((s) => s.draft.marca, 'marca', 'Toyota')
          .having((s) => s.draft.cilindrata, 'cilindrata', 1490),
    ],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'WorkLogStepSubmitted: salva gli ultimi lavori e avanza',
    build: buildBloc,
    seed: () => const VehicleRegistrationState(currentStep: 3),
    act: (bloc) => bloc.add(
      WorkLogStepSubmitted(
        kmAttuali: 80000,
        kmUltimoTagliando: 75000,
        intervalloTagliando: 15000,
      ),
    ),
    expect: () => [
      isA<VehicleRegistrationState>()
          .having((s) => s.currentStep, 'currentStep', 4)
          .having((s) => s.draft.kmAttuali, 'kmAttuali', 80000)
          .having((s) => s.draft.kmUltimoTagliando, 'kmUltimoTagliando', 75000),
    ],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'PhotoStepSubmitted: ultimo step -> status completed',
    build: buildBloc,
    seed: () => const VehicleRegistrationState(currentStep: 4),
    act: (bloc) => bloc.add(PhotoStepSubmitted()),
    expect: () => [
      isA<VehicleRegistrationState>().having(
        (s) => s.status,
        'status',
        RegistrationStatus.completed,
      ),
    ],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'RegistrationStepBackPressed: torna allo step precedente',
    build: buildBloc,
    seed: () => const VehicleRegistrationState(currentStep: 2),
    act: (bloc) => bloc.add(RegistrationStepBackPressed()),
    expect: () => [const VehicleRegistrationState(currentStep: 1)],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'RegistrationStepBackPressed: non va sotto lo step 0 (nessun nuovo stato, gia\' clampato)',
    build: buildBloc,
    seed: () => const VehicleRegistrationState(currentStep: 0),
    act: (bloc) => bloc.add(RegistrationStepBackPressed()),
    expect: () => [],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'RegistrationStarted: resetta lo stato allo step 0',
    build: buildBloc,
    seed: () => const VehicleRegistrationState(currentStep: 3),
    act: (bloc) => bloc.add(RegistrationStarted()),
    expect: () => [const VehicleRegistrationState()],
  );
}
