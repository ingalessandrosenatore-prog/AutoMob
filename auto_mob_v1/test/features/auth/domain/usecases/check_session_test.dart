// =====================================================================
//  GOLDEN TEST — USE CASE
// ---------------------------------------------------------------------
//  Pattern per testare uno use case: si mocka il repository (con mocktail)
//  e si verifica che lo use case inoltri la chiamata e propaghi il
//  risultato (sia il ramo Right sia il ramo Left di fpdart).
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/auth/domain/entities/app_user.dart';
import 'package:auto_mob_v1/features/auth/domain/repositories/auth_repository.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/check_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late CheckSession usecase;
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    usecase = CheckSession(repository);
  });

  const tUser = AppAuthUser(id: 'u1', email: 'test@automob.it');

  test('inoltra la richiesta al repository e ritorna l\'utente (Right)',
      () async {
    when(() => repository.checkSession())
        .thenAnswer((_) async => const Right(tUser));

    final result = await usecase();

    expect(result, const Right<Failure, AppAuthUser?>(tUser));
    verify(() => repository.checkSession()).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('ritorna Right(null) quando non c\'e\' sessione attiva', () async {
    when(() => repository.checkSession())
        .thenAnswer((_) async => const Right(null));

    final result = await usecase();

    expect(result, const Right<Failure, AppAuthUser?>(null));
  });

  test('propaga il Failure quando il repository fallisce (Left)', () async {
    when(() => repository.checkSession())
        .thenAnswer((_) async => const Left(ServerFailure()));

    final result = await usecase();

    expect(result, const Left<Failure, AppAuthUser?>(ServerFailure()));
  });
}
