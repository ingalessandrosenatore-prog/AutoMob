import 'package:auto_mob_v1/features/auth/data/datasources/owner_access_remote_data_source.dart';
import 'package:auto_mob_v1/features/auth/data/repositories/owner_access_repository_impl.dart';
import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/auth/domain/entities/owner_registration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockRemote extends Mock implements OwnerAccessRemoteDataSource {}

void main() {
  test('forbidden maps to role rejection instead of ready', () async {
    final remote = MockRemote();
    when(
      () => remote.resolve(),
    ).thenThrow(const FunctionException(status: 403));
    final result = await OwnerAccessRepositoryImpl(remote).resolve();
    expect(result.getLeft().toNullable(), isA<PermissionFailure>());
  });

  test('server unavailable never grants access', () async {
    final remote = MockRemote();
    when(
      () => remote.resolve(),
    ).thenThrow(const FunctionException(status: 503));
    expect(
      (await OwnerAccessRepositoryImpl(remote).resolve()).isLeft(),
      isTrue,
    );
  });

  test('keeps server onboarding state', () async {
    final remote = MockRemote();
    const pending = OwnerAccess(
      needsCompletion: true,
      profile: OwnerRegistration(),
    );
    when(() => remote.resolve()).thenAnswer((_) async => pending);
    expect(
      (await OwnerAccessRepositoryImpl(
        remote,
      ).resolve()).toOption().toNullable(),
      pending,
    );
  });
}
