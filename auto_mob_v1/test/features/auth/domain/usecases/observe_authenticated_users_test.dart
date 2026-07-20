import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/auth/domain/entities/app_user.dart';
import 'package:auto_mob_v1/features/auth/domain/repositories/auth_repository.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/observe_authenticated_users.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('inoltra al repository il flusso delle sessioni autenticate', () async {
    final repository = MockAuthRepository();
    final usecase = ObserveAuthenticatedUsers(repository);
    const user = AppAuthUser(id: 'u1', email: 'test@automob.it');
    when(
      () => repository.observeAuthenticatedUsers(),
    ).thenAnswer((_) => Stream.value(const Right(user)));

    await expectLater(
      usecase(),
      emits(const Right<Failure, AppAuthUser>(user)),
    );
    verify(() => repository.observeAuthenticatedUsers()).called(1);
  });
}
