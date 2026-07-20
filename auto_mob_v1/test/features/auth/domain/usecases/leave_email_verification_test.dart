import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/auth/domain/repositories/auth_repository.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/leave_email_verification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('cancella la verifica pendente tramite il repository', () async {
    final repository = MockAuthRepository();
    final usecase = LeaveEmailVerification(repository);
    when(
      () => repository.clearPendingEmailVerification(),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase();

    expect(result, const Right<Failure, void>(null));
    verify(() => repository.clearPendingEmailVerification()).called(1);
  });
}
