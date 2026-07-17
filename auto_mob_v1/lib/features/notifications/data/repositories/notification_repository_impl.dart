import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../../domain/entities/notification_message.dart';
import '../../domain/entities/notification_permission_status.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/firebase_messaging_data_source.dart';
import '../datasources/notification_local_data_source.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    required this.messaging,
    required this.local,
    required this.remote,
  });

  final FirebaseMessagingDataSource messaging;
  final NotificationLocalDataSource local;
  final NotificationRemoteDataSource remote;

  @override
  bool get messagingAvailable => messaging.isAvailable;

  @override
  Stream<void> get tokenRefreshes => messaging.tokenRefreshes.map((_) {});

  @override
  Stream<NotificationMessage> get foregroundMessages =>
      messaging.foregroundMessages.map(_toDomainMessage);

  @override
  Stream<NotificationMessage> get openedMessages =>
      messaging.openedMessages.map(_toDomainMessage);

  @override
  Future<NotificationMessage?> initialMessage() async {
    final message = await messaging.getInitialMessage();
    return message == null ? null : _toDomainMessage(message);
  }

  @override
  Future<Either<Failure, bool>> shouldOfferPermission() async {
    try {
      if (!messaging.isAvailable) return const Right(false);
      final status = await messaging.permissionStatus();
      if (status.canReceiveNotifications) {
        return const Right(false);
      }

      // Su Android 13+ Firebase restituisce `denied` sia quando l'utente ha
      // rifiutato, sia quando il popup di sistema non e' mai stato mostrato.
      // Il flag locale e' quindi la fonte che distingue i due casi: viene
      // salvato subito dopo requestPermission(), qualunque sia la risposta.
      return Right(await local.shouldOfferPermission());
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, NotificationPermissionStatus>>
  requestPermission() async {
    try {
      final status = await messaging.requestPermission();
      await local.markPermissionRequested();
      return Right(status);
    } catch (_) {
      return const Left(PermissionFailure());
    }
  }

  @override
  Future<Either<Failure, void>> postponePermissionPrompt() async {
    try {
      await local.postponePermissionPrompt();
      return const Right(null);
    } catch (_) {
      return const Left(StorageFailure());
    }
  }

  @override
  Future<Either<Failure, void>> registerCurrentDevice() async {
    try {
      final status = await messaging.permissionStatus();
      if (!status.canReceiveNotifications) return const Right(null);
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return const Right(null);
      await remote.registerToken(token: token, platform: _platform);
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> unregisterCurrentDevice() async {
    try {
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await remote.unregisterToken(token);
      }
      return const Right(null);
    } catch (_) {
      // Il logout non deve rimanere bloccato se FCM non risponde.
      return const Left(ServerFailure());
    }
  }

  String get _platform {
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  NotificationMessage _toDomainMessage(RemoteMessage message) =>
      NotificationMessage(
        data: Map<String, dynamic>.from(message.data),
        title: message.notification?.title,
        body: message.notification?.body,
      );
}
