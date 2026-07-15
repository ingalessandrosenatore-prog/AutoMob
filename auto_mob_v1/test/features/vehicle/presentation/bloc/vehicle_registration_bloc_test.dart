import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_draft.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_lookup_result.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_save_outcome.dart';
import 'package:auto_mob_v1/features/vehicle/domain/failures/vehicle_lookup_failure.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/clear_vehicle_draft.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/load_vehicle_draft.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/lookup_mechanic_by_code.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/lookup_vehicle_by_plate.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/save_draft_step.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/save_vehicle.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/vehicle_registration_bloc.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/vehicle_registration_event.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/vehicle_registration_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLookupVehicle extends Mock implements LookupVehicleByPlate {}

class MockLookupMechanic extends Mock implements LookupMechanicByCode {}

class MockSaveDraft extends Mock implements SaveDraftStep {}

class MockLoadDraft extends Mock implements LoadVehicleDraft {}

class MockClearDraft extends Mock implements ClearVehicleDraft {}

class MockSaveVehicle extends Mock implements SaveVehicle {}

void main() {
  late MockLookupVehicle lookupVehicle;
  late MockLookupMechanic lookupMechanic;
  late MockSaveDraft saveDraft;
  late MockLoadDraft loadDraft;
  late MockClearDraft clearDraft;
  late MockSaveVehicle saveVehicle;

  setUpAll(() => registerFallbackValue(const VehicleDraft()));

  setUp(() {
    lookupVehicle = MockLookupVehicle();
    lookupMechanic = MockLookupMechanic();
    saveDraft = MockSaveDraft();
    loadDraft = MockLoadDraft();
    clearDraft = MockClearDraft();
    saveVehicle = MockSaveVehicle();
    when(() => saveDraft(any())).thenAnswer((_) async => const Right(null));
    when(() => loadDraft()).thenAnswer((_) async => const Right(null));
    when(() => clearDraft()).thenAnswer((_) async => const Right(null));
  });

  VehicleRegistrationBloc buildBloc() => VehicleRegistrationBloc(
    lookupVehicleByPlate: lookupVehicle,
    lookupMechanicByCode: lookupMechanic,
    saveDraftStep: saveDraft,
    loadVehicleDraft: loadDraft,
    clearVehicleDraft: clearDraft,
    saveVehicle: saveVehicle,
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'ripristina una bozza consumata direttamente al terzo step',
    setUp: () => when(() => loadDraft()).thenAnswer(
      (_) async => const Right(
        VehicleDraft(targa: 'AB123CD', lookupAttemptConsumed: true),
      ),
    ),
    build: buildBloc,
    act: (bloc) => bloc.add(RegistrationStarted()),
    expect: () => [
      isA<VehicleRegistrationState>()
          .having((s) => s.currentStep, 'step', 2)
          .having((s) => s.draft.lookupAttemptConsumed, 'consumed', true),
    ],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'targa non valida non consuma il tentativo e resta allo step targa',
    setUp: () => when(
      () => lookupVehicle('ABC'),
    ).thenAnswer((_) async => const Left(InvalidPlateLookupFailure())),
    build: buildBloc,
    seed: () => const VehicleRegistrationState(currentStep: 1),
    act: (bloc) => bloc.add(PlateSubmitted(targa: 'ABC')),
    expect: () => [
      isA<VehicleRegistrationState>().having(
        (s) => s.lookupStatus,
        'status',
        RegistrationLookupStatus.loading,
      ),
      isA<VehicleRegistrationState>()
          .having((s) => s.currentStep, 'step', 1)
          .having((s) => s.draft.lookupAttemptConsumed, 'consumed', false),
    ],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'inserimento manuale salva la targa e apre Verifica senza chiamare API',
    build: buildBloc,
    seed: () => const VehicleRegistrationState(currentStep: 1),
    act: (bloc) => bloc.add(ManualPlateSubmitted(targa: 'ab 123 cd')),
    expect: () => [
      isA<VehicleRegistrationState>()
          .having((s) => s.currentStep, 'step', 2)
          .having((s) => s.draft.targa, 'targa', 'AB123CD')
          .having((s) => s.draft.datiInModifica, 'edit', true)
          .having((s) => s.draft.lookupId, 'lookup', isNull)
          .having(
            (s) => s.lookupStatus,
            'status',
            RegistrationLookupStatus.idle,
          ),
    ],
    verify: (_) {
      verifyNever(() => lookupVehicle(any()));
      verify(() => saveDraft(any())).called(1);
    },
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'una bozza manuale con targa riparte da Verifica',
    setUp: () => when(() => loadDraft()).thenAnswer(
      (_) async => const Right(
        VehicleDraft(targa: 'AB123CD', marca: 'Fiat', datiInModifica: true),
      ),
    ),
    build: buildBloc,
    act: (bloc) => bloc.add(RegistrationStarted()),
    expect: () => [
      isA<VehicleRegistrationState>()
          .having((s) => s.currentStep, 'step', 2)
          .having((s) => s.draft.marca, 'marca', 'Fiat'),
    ],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'timeout è riprovabile e non consuma il tentativo',
    setUp: () => when(
      () => lookupVehicle('AB123CD'),
    ).thenAnswer((_) async => const Left(TimeoutLookupFailure())),
    build: buildBloc,
    seed: () => const VehicleRegistrationState(currentStep: 1),
    act: (bloc) => bloc.add(PlateSubmitted(targa: 'AB123CD')),
    expect: () => [
      isA<VehicleRegistrationState>(),
      isA<VehicleRegistrationState>()
          .having((s) => s.lookupFailure?.isRetryable, 'retryable', true)
          .having((s) => s.draft.lookupAttemptConsumed, 'consumed', false),
    ],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'risposta parziale consuma il tentativo e apre il terzo step in edit',
    setUp: () => when(() => lookupVehicle('CC000CC')).thenAnswer(
      (_) async => const Right(
        VehicleLookupResult(
          lookupId: 'lookup-cc',
          quality: VehicleLookupQuality.partial,
          plate: 'CC000CC',
          marca: 'Fiat',
        ),
      ),
    ),
    build: buildBloc,
    seed: () => const VehicleRegistrationState(currentStep: 1),
    act: (bloc) => bloc.add(PlateSubmitted(targa: 'CC000CC')),
    expect: () => [
      isA<VehicleRegistrationState>(),
      isA<VehicleRegistrationState>()
          .having((s) => s.currentStep, 'step', 2)
          .having(
            (s) => s.lookupStatus,
            'status',
            RegistrationLookupStatus.partial,
          )
          .having((s) => s.draft.datiInModifica, 'edit', true)
          .having((s) => s.draft.lookupAttemptConsumed, 'consumed', true),
    ],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'chiudere un errore abilita i dati manuali e azzera il popup',
    build: buildBloc,
    seed: () => const VehicleRegistrationState(
      currentStep: 2,
      lookupStatus: RegistrationLookupStatus.failure,
      lookupFailure: BadRequestLookupFailure(),
      draft: VehicleDraft(targa: 'ER400ER', lookupAttemptConsumed: true),
    ),
    act: (bloc) => bloc.add(LookupClosedWithManualEntry()),
    expect: () => [
      isA<VehicleRegistrationState>()
          .having((s) => s.currentStep, 'step', 2)
          .having((s) => s.lookupStatus, 'popup', RegistrationLookupStatus.idle)
          .having((s) => s.lookupFailure, 'errore', isNull)
          .having((s) => s.draft.datiInModifica, 'edit', true),
    ],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'dopo la chiusura del popup il salvataggio manuale avanza senza riaprirlo',
    build: buildBloc,
    seed: () => const VehicleRegistrationState(
      currentStep: 2,
      lookupStatus: RegistrationLookupStatus.idle,
      draft: VehicleDraft(
        targa: 'AB123CD',
        lookupAttemptConsumed: true,
        datiInModifica: true,
      ),
    ),
    act: (bloc) => bloc.add(
      VerifyStepSubmitted(targa: 'AB123CD', marca: 'Fiat', modello: 'Panda'),
    ),
    expect: () => [
      isA<VehicleRegistrationState>()
          .having((s) => s.currentStep, 'step', 3)
          .having((s) => s.lookupStatus, 'popup', RegistrationLookupStatus.idle)
          .having((s) => s.lookupFailure, 'errore', isNull),
    ],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'visualizzare i dati parziali azzera il popup senza cambiare step',
    build: buildBloc,
    seed: () => const VehicleRegistrationState(
      currentStep: 2,
      lookupStatus: RegistrationLookupStatus.partial,
      draft: VehicleDraft(targa: 'CC000CC', datiInModifica: true),
    ),
    act: (bloc) => bloc.add(LookupDialogAcknowledged()),
    expect: () => [
      isA<VehicleRegistrationState>()
          .having((s) => s.currentStep, 'step', 2)
          .having(
            (s) => s.lookupStatus,
            'popup',
            RegistrationLookupStatus.idle,
          ),
    ],
  );

  blocTest<VehicleRegistrationBloc, VehicleRegistrationState>(
    'salvataggio finale completa anche se la copia foto fallisce',
    setUp: () => when(() => saveVehicle(any())).thenAnswer(
      (_) async => const Right(
        VehicleSaveOutcome(vehicleId: 'vehicle-1', photoSaved: false),
      ),
    ),
    build: buildBloc,
    seed: () => const VehicleRegistrationState(
      currentStep: 4,
      draft: VehicleDraft(targa: 'AB123CD'),
    ),
    act: (bloc) => bloc.add(PhotoStepSubmitted()),
    expect: () => [
      isA<VehicleRegistrationState>().having(
        (s) => s.status,
        'status',
        RegistrationStatus.loading,
      ),
      isA<VehicleRegistrationState>()
          .having((s) => s.status, 'status', RegistrationStatus.completed)
          .having((s) => s.photoWarning, 'warning foto', true),
    ],
    verify: (_) => verify(() => clearDraft()).called(1),
  );
}
