// =====================================================================
//  GOLDEN TEST — USE CASE
// ---------------------------------------------------------------------
//  Pattern per testare uno use case: si mocka il repository (con mocktail)
//  e si verifica che lo use case inoltri la chiamata e propaghi il
//  risultato (sia il ramo Right sia il ramo Left di fpdart).
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/auth/domain/entities/signup_outcome.dart';
import 'package:auto_mob_v1/features/auth/domain/entities/pending_email_verification.dart';
import 'package:auto_mob_v1/features/auth/domain/repositories/auth_repository.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/signup_with_email.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignupWithEmail usecase;
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    usecase = SignupWithEmail(repository);
  });

  const tName = 'Mario Rossi';
  const tEmail = 'test@automob.it';
  const tPassword = 'password123';
  const tPasswordConfirmation = 'password123';
  const tPhone = '+39 333 1234567';
  const tPostalCode = '10121';

  test(
    'inoltra nome, email e password al repository e ritorna l\'utente (Right)',
    () async {
      when(
        () => repository.signupWithEmail(
          tName,
          tEmail,
          tPassword,
          tPhone,
          tPostalCode,
        ),
      ).thenAnswer(
        (_) async => const Right(
          SignupConfirmationRequired(PendingEmailVerification(email: tEmail)),
        ),
      );

      final result = await usecase(
        tName,
        tEmail,
        tPassword,
        tPasswordConfirmation,
        tPhone,
        tPostalCode,
      );

      expect(
        result,
        const Right<Failure, SignupOutcome>(
          SignupConfirmationRequired(PendingEmailVerification(email: tEmail)),
        ),
      );
      verify(
        () => repository.signupWithEmail(
          tName,
          tEmail,
          tPassword,
          tPhone,
          tPostalCode,
        ),
      ).called(1);
      verifyNoMoreInteractions(repository);
    },
  );

  test('propaga il Failure quando l\'email e\' gia\' in uso (Left)', () async {
    when(
      () => repository.signupWithEmail(
        tName,
        tEmail,
        tPassword,
        tPhone,
        tPostalCode,
      ),
    ).thenAnswer((_) async => const Left(EmailAlreadyInUseFailure()));

    final result = await usecase(
      tName,
      tEmail,
      tPassword,
      tPasswordConfirmation,
      tPhone,
      tPostalCode,
    );

    expect(
      result,
      const Left<Failure, SignupOutcome>(EmailAlreadyInUseFailure()),
    );
  });

  test('normalizza nome ed email prima di chiamare il repository', () async {
    when(
      () => repository.signupWithEmail(
        tName,
        tEmail,
        tPassword,
        tPhone,
        tPostalCode,
      ),
    ).thenAnswer(
      (_) async => const Right(
        SignupConfirmationRequired(PendingEmailVerification(email: tEmail)),
      ),
    );

    await usecase(
      '  $tName  ',
      '  TEST@AUTOMOB.IT ',
      tPassword,
      tPasswordConfirmation,
      '  $tPhone  ',
      '  $tPostalCode  ',
    );

    verify(
      () => repository.signupWithEmail(
        tName,
        tEmail,
        tPassword,
        tPhone,
        tPostalCode,
      ),
    ).called(1);
  });

  test('rifiuta un nome vuoto senza chiamare il repository', () async {
    final result = await usecase(
      '  ',
      tEmail,
      tPassword,
      tPasswordConfirmation,
      tPhone,
      tPostalCode,
    );

    expect(
      result,
      const Left<Failure, SignupOutcome>(
        ValidationFailure('Inserisci il tuo nome.'),
      ),
    );
    verifyNever(
      () => repository.signupWithEmail(any(), any(), any(), any(), any()),
    );
  });

  test('rifiuta una email non valida senza chiamare il repository', () async {
    final result = await usecase(
      tName,
      'email-non-valida',
      tPassword,
      tPasswordConfirmation,
      tPhone,
      tPostalCode,
    );

    expect(
      result,
      const Left<Failure, SignupOutcome>(
        ValidationFailure('Inserisci un indirizzo email valido.'),
      ),
    );
    verifyNever(
      () => repository.signupWithEmail(any(), any(), any(), any(), any()),
    );
  });

  test(
    'rifiuta password sotto gli 8 caratteri senza chiamare il repository',
    () async {
      final result = await usecase(
        tName,
        tEmail,
        '1234567',
        '1234567',
        tPhone,
        tPostalCode,
      );

      expect(result, const Left<Failure, SignupOutcome>(WeakPasswordFailure()));
      verifyNever(
        () => repository.signupWithEmail(any(), any(), any(), any(), any()),
      );
    },
  );

  test('rifiuta password di conferma diversa', () async {
    final result = await usecase(
      tName,
      tEmail,
      tPassword,
      'password-diversa',
      tPhone,
      tPostalCode,
    );

    expect(
      result,
      const Left<Failure, SignupOutcome>(
        ValidationFailure('Le password non coincidono.'),
      ),
    );
  });

  test('rifiuta un numero di telefono troppo corto', () async {
    final result = await usecase(
      tName,
      tEmail,
      tPassword,
      tPasswordConfirmation,
      '123',
      tPostalCode,
    );

    expect(
      result,
      const Left<Failure, SignupOutcome>(
        ValidationFailure('Inserisci un numero di telefono valido.'),
      ),
    );
  });

  test('rifiuta un CAP che non contiene esattamente cinque cifre', () async {
    final result = await usecase(
      tName,
      tEmail,
      tPassword,
      tPasswordConfirmation,
      tPhone,
      '1234A',
    );

    expect(
      result,
      const Left<Failure, SignupOutcome>(
        ValidationFailure('Inserisci un CAP italiano valido.'),
      ),
    );
  });
}
