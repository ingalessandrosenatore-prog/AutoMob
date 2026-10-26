import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/future_work/domain/entities/future_work_report.dart';
import 'package:auto_mob_v1/features/future_work/domain/entities/warning_light_observation.dart';
import 'package:auto_mob_v1/features/future_work/domain/repositories/future_work_repository.dart';
import 'package:auto_mob_v1/features/future_work/domain/usecases/create_future_work_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockFutureWorkRepository extends Mock implements FutureWorkRepository {}

void main() {
  late _MockFutureWorkRepository repository;
  late CreateFutureWorkReport useCase;

  setUp(() {
    repository = _MockFutureWorkRepository();
    useCase = CreateFutureWorkReport(
      repository,
      now: () => DateTime(2026, 9, 17, 15),
    );
  });

  test('accepts a light-only report and keeps onboard text separate', () async {
    const lights = [
      WarningLightObservation(code: 'S03', color: 'amber', flashing: true),
    ];
    final deadline = DateTime(2026, 9, 20);
    when(
      () => repository.createReport(
        vehicleId: 'v1',
        description: '',
        onboardMessage: 'ABS non disponibile',
        warningLights: lights,
        reminderDate: deadline,
      ),
    ).thenAnswer(
      (_) async => Right(
        FutureWorkReport(
          id: 'r1',
          vehicleId: 'v1',
          description: '',
          onboardMessage: 'ABS non disponibile',
          warningLights: lights,
          reminderDate: deadline,
        ),
      ),
    );
    final result = await useCase(
      vehicleId: 'v1',
      description: '',
      onboardMessage: '  ABS non disponibile  ',
      warningLights: lights,
      reminderDate: deadline,
    );
    expect(result.toNullable()?.description, '');
    expect(result.toNullable()?.onboardMessage, 'ABS non disponibile');
    expect(result.toNullable()?.warningLights, lights);
  });

  test(
    'rejects duplicate lights, unknown codes, colors and oversized messages',
    () async {
      const light = WarningLightObservation(code: 'S03', color: 'amber');
      for (final lights in [
        const [light, light],
        const [WarningLightObservation(code: 'S99', color: 'red')],
        const [WarningLightObservation(code: 'S03', color: 'purple')],
      ]) {
        expect(
          (await useCase(
            vehicleId: 'v1',
            description: 'ABS',
            warningLights: lights,
            reminderDate: DateTime(2026, 9, 20),
          )).isLeft(),
          isTrue,
        );
      }
      expect(
        (await useCase(
          vehicleId: 'v1',
          description: '',
          onboardMessage: 'x' * 1001,
          reminderDate: DateTime(2026, 9, 20),
        )).isLeft(),
        isTrue,
      );
      verifyZeroInteractions(repository);
    },
  );

  test('persists fixed and flashing appearances of the same symbol', () async {
    const lights = [
      WarningLightObservation(code: 'S10', color: 'amber'),
      WarningLightObservation(code: 'S10', color: 'amber', flashing: true),
    ];
    final deadline = DateTime(2026, 9, 20);
    when(
      () => repository.createReport(
        vehicleId: 'v1',
        description: '',
        warningLights: lights,
        reminderDate: deadline,
      ),
    ).thenAnswer(
      (_) async => Right(
        FutureWorkReport(
          id: 'r1',
          vehicleId: 'v1',
          description: '',
          warningLights: lights,
          reminderDate: deadline,
        ),
      ),
    );
    final result = await useCase(
      vehicleId: 'v1',
      description: '',
      warningLights: lights,
      reminderDate: deadline,
    );
    expect(result.toNullable()?.warningLights, lights);
  });

  test('normalizza i dati e crea la segnalazione valida', () async {
    final deadline = DateTime(2026, 9, 20);
    final report = FutureWorkReport(
      id: 'r1',
      vehicleId: 'v1',
      description: 'Controllare i freni',
      reminderDate: deadline,
    );
    when(
      () => repository.createReport(
        vehicleId: 'v1',
        description: 'Controllare i freni',
        reminderDate: deadline,
      ),
    ).thenAnswer((_) async => Right(report));

    final result = await useCase(
      vehicleId: 'v1',
      description: '  Controllare i freni  ',
      reminderDate: DateTime(2026, 9, 20, 18),
    );

    expect(result, Right<Failure, FutureWorkReport>(report));
    verify(
      () => repository.createReport(
        vehicleId: 'v1',
        description: 'Controllare i freni',
        reminderDate: deadline,
      ),
    ).called(1);
  });

  test(
    'rifiuta descrizione vuota e data passata senza interrogare il repo',
    () async {
      final emptyDescription = await useCase(
        vehicleId: 'v1',
        description: '   ',
        reminderDate: DateTime(2026, 9, 20),
      );
      final pastDate = await useCase(
        vehicleId: 'v1',
        description: 'Freni',
        reminderDate: DateTime(2026, 9, 16),
      );

      expect(emptyDescription.isLeft(), isTrue);
      expect(pastDate.isLeft(), isTrue);
      verifyZeroInteractions(repository);
    },
  );
}
