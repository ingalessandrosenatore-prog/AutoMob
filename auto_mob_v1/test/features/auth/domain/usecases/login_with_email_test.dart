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
import 'package:auto_mob_v1/features/auth/domain/usecases/login_with_email.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginWithEmail usecase;
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    usecase = LoginWithEmail(repository);
  });

  const tUser = AppAuthUser(id: 'u1', email: 'test@automob.it');
  const tEmail = 'test@automob.it';
  const tPassword = 'password123';

  test(
    'inoltra email e password al repository e ritorna l\'utente (Right)',
    () async {
      when(
        () => repository.loginWithEmail(tEmail, tPassword),
      ).thenAnswer((_) async => const Right(tUser));

      final result = await usecase(tEmail, tPassword);

      expect(result, const Right<Failure, AppAuthUser>(tUser));
      verify(() => repository.loginWithEmail(tEmail, tPassword)).called(1);
      verifyNoMoreInteractions(repository);
    },
  );

  test('propaga il Failure quando le credenziali sono errate (Left)', () async {
    when(() => repository.loginWithEmail(tEmail, tPassword)).thenAnswer(
      (_) async => const Left(AuthFailure('Credenziali non valide.')),
    );

    final result = await usecase(tEmail, tPassword);

    expect(
      result,
      const Left<Failure, AppAuthUser>(AuthFailure('Credenziali non valide.')),
    );
  });
}
