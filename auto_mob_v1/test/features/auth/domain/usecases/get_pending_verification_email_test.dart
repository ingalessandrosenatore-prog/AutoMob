import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/auth/domain/repositories/auth_repository.dart';
import 'package:auto_mob_v1/features/auth/domain/entities/pending_email_verification.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/get_pending_verification_email.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('inoltra il recupero dell\'email di verifica pendente', () async {
    final repository = MockAuthRepository();
    final usecase = GetPendingVerificationEmail(repository);
    const pending = PendingEmailVerification(email: 'test@automob.it');
    when(
      () => repository.getPendingEmailVerification(),
    ).thenAnswer((_) async => const Right(pending));

    final result = await usecase();

    expect(result, const Right<Failure, PendingEmailVerification?>(pending));
    verify(() => repository.getPendingEmailVerification()).called(1);
  });
}
