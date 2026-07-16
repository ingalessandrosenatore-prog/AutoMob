import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/notifications/data/datasources/firebase_messaging_data_source.dart';
import 'package:auto_mob_v1/features/notifications/data/datasources/notification_local_data_source.dart';
import 'package:auto_mob_v1/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:auto_mob_v1/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:auto_mob_v1/features/notifications/domain/entities/notification_permission_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockMessaging extends Mock implements FirebaseMessagingDataSource {}

class _MockLocal extends Mock implements NotificationLocalDataSource {}

class _MockRemote extends Mock implements NotificationRemoteDataSource {}

void main() {
  late _MockMessaging messaging;
  late _MockLocal local;
  late _MockRemote remote;
  late NotificationRepositoryImpl repository;

  setUp(() {
    messaging = _MockMessaging();
    local = _MockLocal();
    remote = _MockRemote();
    repository = NotificationRepositoryImpl(
      messaging: messaging,
      local: local,
      remote: remote,
    );
  });

  test('non offre il permesso quando Firebase non e configurato', () async {
    when(() => messaging.isAvailable).thenReturn(false);

    final result = await repository.shouldOfferPermission();

    expect(result, const Right(false));
    verifyNever(local.shouldOfferPermission);
  });

  test('offre il permesso quando non e ancora determinato', () async {
    when(() => messaging.isAvailable).thenReturn(true);
    when(
      messaging.permissionStatus,
    ).thenAnswer((_) async => NotificationPermissionStatus.notDetermined);
    when(local.shouldOfferPermission).thenAnswer((_) async => true);

    final result = await repository.shouldOfferPermission();

    expect(result, const Right(true));
  });

  test(
    'offre il permesso su Android quando denied significa mai richiesto',
    () async {
      when(() => messaging.isAvailable).thenReturn(true);
      when(
        messaging.permissionStatus,
      ).thenAnswer((_) async => NotificationPermissionStatus.denied);
      when(local.shouldOfferPermission).thenAnswer((_) async => true);

      final result = await repository.shouldOfferPermission();

      expect(result, const Right(true));
      verify(local.shouldOfferPermission).called(1);
    },
  );

  test('non insiste dopo una richiesta gia rifiutata', () async {
    when(() => messaging.isAvailable).thenReturn(true);
    when(
      messaging.permissionStatus,
    ).thenAnswer((_) async => NotificationPermissionStatus.denied);
    when(local.shouldOfferPermission).thenAnswer((_) async => false);

    final result = await repository.shouldOfferPermission();

    expect(result, const Right(false));
  });

  test('richiede il permesso e ricorda che e stato chiesto', () async {
    when(
      messaging.requestPermission,
    ).thenAnswer((_) async => NotificationPermissionStatus.authorized);
    when(local.markPermissionRequested).thenAnswer((_) async {});

    final result = await repository.requestPermission();

    expect(result, const Right(NotificationPermissionStatus.authorized));
    verify(local.markPermissionRequested).called(1);
  });

  test('registra token solo con permesso valido', () async {
    when(
      messaging.permissionStatus,
    ).thenAnswer((_) async => NotificationPermissionStatus.authorized);
    when(
      messaging.getToken,
    ).thenAnswer((_) async => 'token-di-prova-lungo-123');
    when(
      () => remote.registerToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async {});

    final result = await repository.registerCurrentDevice();

    expect(result, const Right(null));
    verify(
      () => remote.registerToken(
        token: 'token-di-prova-lungo-123',
        platform: any(named: 'platform'),
      ),
    ).called(1);
  });

  test('non registra token quando il permesso e negato', () async {
    when(
      messaging.permissionStatus,
    ).thenAnswer((_) async => NotificationPermissionStatus.denied);

    final result = await repository.registerCurrentDevice();

    expect(result, const Right(null));
    verifyNever(messaging.getToken);
  });

  test('mappa un errore di registrazione in ServerFailure', () async {
    when(messaging.permissionStatus).thenThrow(Exception('firebase'));

    final result = await repository.registerCurrentDevice();

    expect(result, const Left<Failure, void>(ServerFailure()));
  });
}
