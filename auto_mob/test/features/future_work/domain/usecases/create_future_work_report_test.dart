import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/future_work/domain/entities/future_work_report.dart';
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
