import 'package:auto_mob_v1/features/auth/domain/entities/owner_registration.dart';
import 'package:auto_mob_v1/features/auth/domain/repositories/owner_access_repository.dart';
import 'package:auto_mob_v1/features/auth/domain/usecases/resolve_owner_access.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements OwnerAccessRepository {}

void main() {
  test('invalid contact details never reach the backend', () async {
    final repository = MockRepository();
    final usecase = ResolveOwnerAccess(repository);
    for (final data in [
      const OwnerRegistration(
        fullName: 'Mario',
        phone: 'abc3331234567',
        postalCode: '00100',
      ),
      const OwnerRegistration(
        fullName: 'Mario',
        phone: '3331234567',
        postalCode: '100',
      ),
      const OwnerRegistration(phone: '3331234567', postalCode: '00100'),
    ]) {
      expect((await usecase(registration: data)).isLeft(), isTrue);
    }
    verifyZeroInteractions(repository);
  });

  test('inspection preserves incomplete state from the server', () async {
    final repository = MockRepository();
    const pending = OwnerAccess(
      needsCompletion: true,
      profile: OwnerRegistration(),
    );
    when(
      () => repository.resolve(),
    ).thenAnswer((_) async => const Right(pending));
    final result = await ResolveOwnerAccess(repository)();
    expect(result.toOption().toNullable(), pending);
  });
}
