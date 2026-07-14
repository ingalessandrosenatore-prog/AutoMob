// =====================================================================
//  GOLDEN TEST — CUBIT / BLoC (layer presentation)
// ---------------------------------------------------------------------
//  Pattern per testare un Cubit/BLoC: si mocka lo use case (con mocktail)
//  e con blocTest si dichiara la SEQUENZA di stati attesa dopo un'azione.
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/core/types/enum_pop_up.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/selected_part.dart';
import 'package:auto_mob_v1/features/work_log/domain/usecases/create_work_log.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_bloc.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_event.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateWorkLog extends Mock implements CreateWorkLog {}

void main() {
  late MockCreateWorkLog createWorkLog;

  final tServiceDate = DateTime(2026, 6, 16);

  setUp(() {
    createWorkLog = MockCreateWorkLog();
  });

  WorkLogBloc buildBloc() => WorkLogBloc(createWorkLog: createWorkLog);

  blocTest<WorkLogBloc, WorkLogState>(
    'WorkLogEventCohiceTap: aggiunge una parte non ancora selezionata',
    build: buildBloc,
    act: (bloc) => bloc.add(WorkLogEventCohiceTap(isSelected: false, id: 15)),
    expect: () => [
      isA<WorkLogState>()
          .having((s) => s.selectedParts.map((p) => p.partId), 'partIds', [15]),
    ],
  );

  blocTest<WorkLogBloc, WorkLogState>(
    'WorkLogEventCohiceTap: rimuove una parte gia\' selezionata',
    build: buildBloc,
    seed: () => WorkLogState.initial()
        .copyWith(selectedParts: const [SelectedPart(partId: 15)]),
    act: (bloc) => bloc.add(WorkLogEventCohiceTap(isSelected: true, id: 15)),
    expect: () => [
      isA<WorkLogState>()
          .having((s) => s.selectedParts, 'selectedParts', isEmpty),
    ],
  );

  blocTest<WorkLogBloc, WorkLogState>(
    'InitKm: imposta vehicleKm, currentKm e il prossimo richiamo',
    build: buildBloc,
    act: (bloc) => bloc.add(InitKm(vehicleKm: 10000)),
    expect: () => [
      isA<WorkLogState>()
          .having((s) => s.vehicleKm, 'vehicleKm', 10000)
          .having((s) => s.currentKm, 'currentKm', 10000)
          .having((s) => s.prosssimoRichiamo, 'prosssimoRichiamo', 10000),
    ],
  );

  blocTest<WorkLogBloc, WorkLogState>(
    'CurrentKmChange: ricalcola il prossimo richiamo',
    build: buildBloc,
    seed: () => WorkLogState.initial().copyWith(intervallKM: 15000),
    act: (bloc) => bloc.add(CurrentKmChange(currentKm: 12000)),
    expect: () => [
      isA<WorkLogState>()
          .having((s) => s.currentKm, 'currentKm', 12000)
          .having((s) => s.prosssimoRichiamo, 'prosssimoRichiamo', 27000),
    ],
  );

  blocTest<WorkLogBloc, WorkLogState>(
    'RichiamoChange: aggiorna intervallo e prossimo richiamo',
    build: buildBloc,
    seed: () => WorkLogState.initial().copyWith(currentKm: 12000),
    act: (bloc) => bloc.add(RichiamoChange(intervallKM: 20000)),
    expect: () => [
      isA<WorkLogState>()
          .having((s) => s.intervallKM, 'intervallKM', 20000)
          .having((s) => s.prosssimoRichiamo, 'prosssimoRichiamo', 32000),
    ],
  );

  blocTest<WorkLogBloc, WorkLogState>(
    'RemovePartEvent: rimuove solo la parte richiesta',
    build: buildBloc,
    seed: () => WorkLogState.initial().copyWith(
      selectedParts: const [SelectedPart(partId: 15), SelectedPart(partId: 20)],
    ),
    act: (bloc) => bloc.add(RemovePartEvent(partId: 15)),
    expect: () => [
      isA<WorkLogState>().having(
          (s) => s.selectedParts.map((p) => p.partId), 'partIds', [20]),
    ],
  );

  blocTest<WorkLogBloc, WorkLogState>(
    'UpdatePartItemEvent: sostituisce la parte con lo stesso partId',
    build: buildBloc,
    seed: () => WorkLogState.initial()
        .copyWith(selectedParts: const [SelectedPart(partId: 15, quantity: 1)]),
    act: (bloc) => bloc
        .add(UpdatePartItemEvent(item: const SelectedPart(partId: 15, quantity: 3))),
    expect: () => [
      isA<WorkLogState>().having(
          (s) => s.selectedParts.single.quantity, 'quantity', 3),
    ],
  );

  blocTest<WorkLogBloc, WorkLogState>(
    'OnSubmitEvent: blocca senza chiamare il repository se manca il nome custom (tipo Altro)',
    build: buildBloc,
    seed: () => WorkLogState.initial().copyWith(
      type: EnumPopUp.altro,
      customName: '   ',
      vehicleKm: 10000,
      currentKm: 10000,
    ),
    act: (bloc) => bloc.add(OnSubmitEvent(id: 'v1')),
    expect: () => [
      isA<WorkLogState>()
          .having((s) => s.status, 'status', WorkLogStatus.failure),
    ],
    verify: (_) {
      verifyNever(() => createWorkLog(
            vehicleId: any(named: 'vehicleId'),
            type: any(named: 'type'),
            serviceKm: any(named: 'serviceKm'),
            serviceDate: any(named: 'serviceDate'),
            intervallKm: any(named: 'intervallKm'),
            items: any(named: 'items'),
          ));
    },
  );

  blocTest<WorkLogBloc, WorkLogState>(
    'OnSubmitEvent: blocca se i km sono inferiori a quelli attuali del veicolo',
    build: buildBloc,
    seed: () => WorkLogState.initial().copyWith(
      type: EnumPopUp.aggiornaTagliando,
      vehicleKm: 10000,
      currentKm: 9000,
    ),
    act: (bloc) => bloc.add(OnSubmitEvent(id: 'v1')),
    expect: () => [
      isA<WorkLogState>()
          .having((s) => s.status, 'status', WorkLogStatus.failure),
    ],
  );

  blocTest<WorkLogBloc, WorkLogState>(
    'OnSubmitEvent: salva il lavoro e emette [loading, success]',
    build: () {
      when(() => createWorkLog(
            vehicleId: 'v1',
            type: 'tagliando',
            customName: null,
            serviceKm: 12000,
            serviceDate: tServiceDate,
            notes: null,
            intervallKm: 15000,
            items: const [SelectedPart(partId: 15, quantity: 1)],
          )).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    seed: () => WorkLogState.initial().copyWith(
      type: EnumPopUp.aggiornaTagliando,
      vehicleKm: 10000,
      currentKm: 12000,
      intervallKM: 15000,
      serviceDate: tServiceDate,
      selectedParts: const [SelectedPart(partId: 15, quantity: 1)],
    ),
    act: (bloc) => bloc.add(OnSubmitEvent(id: 'v1')),
    expect: () => [
      isA<WorkLogState>()
          .having((s) => s.status, 'status', WorkLogStatus.loading),
      isA<WorkLogState>()
          .having((s) => s.status, 'status', WorkLogStatus.success),
    ],
  );

  blocTest<WorkLogBloc, WorkLogState>(
    'OnSubmitEvent: emette [loading, failure] quando il salvataggio fallisce',
    build: () {
      when(() => createWorkLog(
            vehicleId: 'v1',
            type: 'tagliando',
            customName: null,
            serviceKm: 12000,
            serviceDate: tServiceDate,
            notes: null,
            intervallKm: 15000,
            items: const [SelectedPart(partId: 15, quantity: 1)],
          )).thenAnswer((_) async => const Left(ServerFailure()));
      return buildBloc();
    },
    seed: () => WorkLogState.initial().copyWith(
      type: EnumPopUp.aggiornaTagliando,
      vehicleKm: 10000,
      currentKm: 12000,
      intervallKM: 15000,
      serviceDate: tServiceDate,
      selectedParts: const [SelectedPart(partId: 15, quantity: 1)],
    ),
    act: (bloc) => bloc.add(OnSubmitEvent(id: 'v1')),
    expect: () => [
      isA<WorkLogState>()
          .having((s) => s.status, 'status', WorkLogStatus.loading),
      isA<WorkLogState>()
          .having((s) => s.status, 'status', WorkLogStatus.failure)
          .having((s) => s.errorMessage, 'errorMessage', const ServerFailure().message),
    ],
  );

  blocTest<WorkLogBloc, WorkLogState>(
    'WorkLogWizardStepChanged aggiorna lo step e lo mantiene tra 0 e 2',
    build: buildBloc,
    act: (bloc) {
      bloc
        ..add(WorkLogWizardStepChanged(1))
        ..add(WorkLogWizardStepChanged(8));
    },
    expect: () => [
      isA<WorkLogState>().having((state) => state.currentStep, 'currentStep', 1),
      isA<WorkLogState>().having((state) => state.currentStep, 'currentStep', 2),
    ],
  );
}
