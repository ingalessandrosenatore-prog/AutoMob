import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/auth/domain/repositories/auth_repository.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/resend_confirmation_email.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('inoltra al repository la richiesta di reinvio', () async {
    final repository = MockAuthRepository();
    final usecase = ResendConfirmationEmail(repository);
    when(
      () => repository.resendConfirmationEmail('test@automob.it'),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase('test@automob.it');

    expect(result, const Right<Failure, void>(null));
    verify(
      () => repository.resendConfirmationEmail('test@automob.it'),
    ).called(1);
  });
}
