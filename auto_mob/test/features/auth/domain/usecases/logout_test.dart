// =====================================================================
//  GOLDEN TEST — USE CASE
// ---------------------------------------------------------------------
//  Pattern per testare uno use case: si mocka il repository (con mocktail)
//  e si verifica che lo use case inoltri la chiamata e propaghi il
//  risultato (sia il ramo Right sia il ramo Left di fpdart).
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/auth/domain/repositories/auth_repository.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/logout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late Logout usecase;
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    usecase = Logout(repository);
  });

  test('inoltra la richiesta di logout al repository (Right)', () async {
    when(() => repository.logout()).thenAnswer((_) async => const Right(null));

    final result = await usecase();

    expect(result, const Right<Failure, void>(null));
    verify(() => repository.logout()).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('propaga il Failure quando il repository fallisce (Left)', () async {
    when(
      () => repository.logout(),
    ).thenAnswer((_) async => const Left(ServerFailure()));

    final result = await usecase();

    expect(result, const Left<Failure, void>(ServerFailure()));
  });
}
