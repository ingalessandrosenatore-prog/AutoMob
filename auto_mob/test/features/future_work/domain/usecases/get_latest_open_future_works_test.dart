import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/future_work/domain/entities/future_work_summary.dart';
import 'package:auto_mob_v1/features/future_work/domain/repositories/future_work_repository.dart';
import 'package:auto_mob_v1/features/future_work/domain/usecases/get_latest_open_future_works.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockFutureWorkRepository extends Mock implements FutureWorkRepository {}

void main() {
  test('restituisce la lista del repository senza trasformazioni', () async {
    final repository = _MockFutureWorkRepository();
    final useCase = GetLatestOpenFutureWorks(repository);
    final items = [
      FutureWorkSummary(
        id: 'i1',
        recordId: 'r1',
        vehicleId: 'v1',
        description: 'Freni',
        registeredAt: DateTime(2026, 9, 17),
        reminderDate: DateTime(2026, 9, 30),
      ),
    ];
    when(
      () => repository.getLatestOpen(),
    ).thenAnswer((_) async => Right(items));

    final result = await useCase();

    expect(result, Right<Failure, List<FutureWorkSummary>>(items));
    verify(() => repository.getLatestOpen()).called(1);
  });
}
