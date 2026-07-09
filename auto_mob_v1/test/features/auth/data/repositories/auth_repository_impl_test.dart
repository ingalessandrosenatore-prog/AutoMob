// =====================================================================
//  GOLDEN TEST — REPOSITORY (layer data)
// ---------------------------------------------------------------------
//  Pattern per testare un repository: si mocka il datasource (NON si
//  tocca DB/rete) e si verifica la mappatura Exception -> Failure e il
//  passaggio dei valori.
//
//  NB: loginWithGoogle e loginWithApple non sono ancora una feature
//  sviluppata/collegata in UI: NON testati qui di proposito (vedi
//  report di fine loop).
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exceptions.dart';
import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:auto_mob_v1/features/auth/data/models/app_user_model.dart';
import 'package:auto_mob_v1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:auto_mob_v1/features/auth/domain/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource remote;

  setUp(() {
    remote = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: remote);
  });

  const tUserModel = AppAuthUserModel(id: 'u1', email: 'test@automob.it');
  const tEmail = 'test@automob.it';
  const tPassword = 'password123';
  const tName = 'Mario Rossi';

  group('loginWithEmail', () {
    test('ritorna Right con l\'utente quando il datasource risponde',
        () async {
      when(() => remote.loginWithEmail(tEmail, tPassword))
          .thenAnswer((_) async => tUserModel);

      final result = await repository.loginWithEmail(tEmail, tPassword);

      expect(result, const Right<Failure, AppAuthUser>(tUserModel));
      verify(() => remote.loginWithEmail(tEmail, tPassword)).called(1);
    });

    test('mappa AuthDataSourceException(401) in AuthFailure', () async {
      when(() => remote.loginWithEmail(tEmail, tPassword)).thenThrow(
        const AuthDataSourceException('Credenziali errate', code: '401'),
      );

      final result = await repository.loginWithEmail(tEmail, tPassword);

      expect(
        result,
        const Left<Failure, AppAuthUser>(AuthFailure('Email o password errati')),
      );
    });

    test('mappa NetworkException in NetworkFailure', () async {
      when(() => remote.loginWithEmail(tEmail, tPassword))
          .thenThrow(const NetworkException());

      final result = await repository.loginWithEmail(tEmail, tPassword);

      expect(result, const Left<Failure, AppAuthUser>(NetworkFailure()));
    });

    test('mappa EmailNotConfirmedException in EmailNotConfirmedFailure',
        () async {
      when(() => remote.loginWithEmail(tEmail, tPassword))
          .thenThrow(const EmailNotConfirmedException());

      final result = await repository.loginWithEmail(tEmail, tPassword);

      expect(
        result,
        const Left<Failure, AppAuthUser>(EmailNotConfirmedFailure()),
      );
    });
  });

  group('signupWithEmail', () {
    test('ritorna Right con l\'utente quando il datasource risponde',
        () async {
      when(() => remote.signupWithEmail(tName, tEmail, tPassword))
          .thenAnswer((_) async => tUserModel);

      final result = await repository.signupWithEmail(tName, tEmail, tPassword);

      expect(result, const Right<Failure, AppAuthUser>(tUserModel));
      verify(() => remote.signupWithEmail(tName, tEmail, tPassword)).called(1);
    });

    test('mappa AuthDataSourceException(422 email) in EmailAlreadyInUseFailure',
        () async {
      when(() => remote.signupWithEmail(tName, tEmail, tPassword)).thenThrow(
        const AuthDataSourceException('email già registrata', code: '422'),
      );

      final result = await repository.signupWithEmail(tName, tEmail, tPassword);

      expect(
        result,
        const Left<Failure, AppAuthUser>(EmailAlreadyInUseFailure()),
      );
    });

    test('mappa NetworkException in NetworkFailure', () async {
      when(() => remote.signupWithEmail(tName, tEmail, tPassword))
          .thenThrow(const NetworkException());

      final result = await repository.signupWithEmail(tName, tEmail, tPassword);

      expect(result, const Left<Failure, AppAuthUser>(NetworkFailure()));
    });
  });

  group('logout', () {
    test('ritorna Right(null) quando il datasource risponde', () async {
      when(() => remote.logout()).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result, const Right<Failure, void>(null));
      verify(() => remote.logout()).called(1);
    });

    test('mappa NetworkException in NetworkFailure', () async {
      when(() => remote.logout()).thenThrow(const NetworkException());

      final result = await repository.logout();

      expect(result, const Left<Failure, void>(NetworkFailure()));
    });
  });

  group('checkSession', () {
    test('ritorna Right con l\'utente quando c\'e\' una sessione attiva',
        () async {
      when(() => remote.checkSession()).thenAnswer((_) async => tUserModel);

      final result = await repository.checkSession();

      expect(result, const Right<Failure, AppAuthUser?>(tUserModel));
    });

    test('ritorna Right(null) quando non c\'e\' sessione attiva', () async {
      when(() => remote.checkSession()).thenAnswer((_) async => null);

      final result = await repository.checkSession();

      expect(result, const Right<Failure, AppAuthUser?>(null));
    });

    test('mappa NetworkException in NetworkFailure', () async {
      when(() => remote.checkSession()).thenThrow(const NetworkException());

      final result = await repository.checkSession();

      expect(result, const Left<Failure, AppAuthUser?>(NetworkFailure()));
    });
  });
}
