import 'package:auto_mob_v1/features/future_work/domain/repositories/future_work_repository.dart';
import 'package:auto_mob_v1/features/future_work/domain/usecases/mark_future_work_done.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements FutureWorkRepository {}

void main() {
  test('completes the requested record and rejects empty IDs', () async {
    final repo = _Repository();
    when(() => repo.markDone('r1')).thenAnswer((_) async => const Right(null));
    final useCase = MarkFutureWorkDone(repo);
    expect((await useCase('r1')).isRight(), isTrue);
    expect((await useCase(' ')).isLeft(), isTrue);
    verify(() => repo.markDone('r1')).called(1);
    verifyNoMoreInteractions(repo);
  });
}
