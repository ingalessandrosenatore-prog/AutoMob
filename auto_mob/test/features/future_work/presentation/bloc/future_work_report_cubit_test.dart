import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/future_work/domain/entities/future_work_report.dart';
import 'package:auto_mob_v1/features/future_work/domain/usecases/create_future_work_report.dart';
import 'package:auto_mob_v1/features/future_work/presentation/bloc/future_work_report_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreateFutureWorkReport extends Mock
    implements CreateFutureWorkReport {}

void main() {
  late _MockCreateFutureWorkReport createReport;
  final deadline = DateTime(2026, 9, 20);

  setUp(() => createReport = _MockCreateFutureWorkReport());

  test(
    'collects independent observations and updates/removes a selected light',
    () async {
      final cubit = FutureWorkReportCubit(createReport);
      addTearDown(cubit.close);
      cubit.toggleWarning('S03', color: 'red', flashing: true);
      cubit.onboardMessageChanged('ABS non disponibile');
      cubit.reminderDateChanged(deadline);
      expect(cubit.state.description, '');
      expect(cubit.state.canSubmit, isTrue);
      expect(cubit.state.warningLights.single.color, 'red');
      expect(cubit.state.warningLights.single.flashing, isTrue);
      cubit.toggleWarning('S03', color: 'red', flashing: true);
      expect(cubit.state.warningLights, isEmpty);
      expect(cubit.state.onboardMessage, 'ABS non disponibile');
      expect(cubit.state.canSubmit, isTrue);
    },
  );

  test('keeps fixed and flashing variants independent', () async {
    final cubit = FutureWorkReportCubit(createReport);
    addTearDown(cubit.close);
    cubit.toggleWarning('S10', color: 'amber');
    cubit.toggleWarning('S10', color: 'amber', flashing: true);
    expect(cubit.state.warningLights.length, 2);
    cubit.toggleWarning('S10', color: 'amber');
    expect(cubit.state.warningLights.single.flashing, isTrue);
    cubit.toggleWarning('S10', color: 'amber', flashing: true);
    expect(cubit.state.warningLights, isEmpty);
  });

  blocTest<FutureWorkReportCubit, FutureWorkReportState>(
    'raccoglie descrizione e data, poi emette submitting e success',
    build: () {
      when(
        () => createReport(
          vehicleId: 'v1',
          description: 'Freni',
          reminderDate: deadline,
        ),
      ).thenAnswer(
        (_) async => Right(
          FutureWorkReport(
            id: 'r1',
            vehicleId: 'v1',
            description: 'Freni',
            reminderDate: deadline,
          ),
        ),
      );
      return FutureWorkReportCubit(createReport);
    },
    act: (cubit) async {
      cubit.descriptionChanged('Freni');
      cubit.reminderDateChanged(deadline);
      await cubit.submit('v1');
    },
    expect: () => [
      const FutureWorkReportState(description: 'Freni'),
      FutureWorkReportState(description: 'Freni', reminderDate: deadline),
      FutureWorkReportState(
        description: 'Freni',
        reminderDate: deadline,
        status: FutureWorkReportStatus.submitting,
      ),
      isA<FutureWorkReportState>()
          .having(
            (state) => state.status,
            'status',
            FutureWorkReportStatus.success,
          )
          .having((state) => state.savedReport?.id, 'report id', 'r1'),
    ],
  );

  blocTest<FutureWorkReportCubit, FutureWorkReportState>(
    'mostra un errore se manca la data',
    build: () => FutureWorkReportCubit(createReport),
    seed: () => const FutureWorkReportState(description: 'Freni'),
    act: (cubit) => cubit.submit('v1'),
    expect: () => [
      isA<FutureWorkReportState>()
          .having(
            (state) => state.status,
            'status',
            FutureWorkReportStatus.failure,
          )
          .having((state) => state.error, 'error', isNotNull),
    ],
    verify: (_) => verifyZeroInteractions(createReport),
  );

  blocTest<FutureWorkReportCubit, FutureWorkReportState>(
    'propaga il messaggio di errore del use case',
    build: () {
      when(
        () => createReport(
          vehicleId: 'v1',
          description: 'Freni',
          reminderDate: deadline,
        ),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return FutureWorkReportCubit(createReport);
    },
    seed: () =>
        FutureWorkReportState(description: 'Freni', reminderDate: deadline),
    act: (cubit) => cubit.submit('v1'),
    expect: () => [
      FutureWorkReportState(
        description: 'Freni',
        reminderDate: deadline,
        status: FutureWorkReportStatus.submitting,
      ),
      isA<FutureWorkReportState>()
          .having(
            (state) => state.status,
            'status',
            FutureWorkReportStatus.failure,
          )
          .having((state) => state.error, 'error', isNotNull),
    ],
  );
}
