import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/entities/notification_permission_status.dart';

abstract interface class FirebaseMessagingDataSource {
  bool get isAvailable;

  Future<NotificationPermissionStatus> permissionStatus();

  Future<NotificationPermissionStatus> requestPermission();

  Future<String?> getToken();

  Stream<String> get tokenRefreshes;

  Stream<RemoteMessage> get foregroundMessages;

  Stream<RemoteMessage> get openedMessages;

  Future<RemoteMessage?> getInitialMessage();
}

class FirebaseMessagingDataSourceImpl implements FirebaseMessagingDataSource {
  FirebaseMessagingDataSourceImpl({required this.firebaseAvailable});

  final bool firebaseAvailable;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  bool get isAvailable => firebaseAvailable;

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    if (!firebaseAvailable) return NotificationPermissionStatus.unavailable;
    return _mapStatus(
      (await _messaging.getNotificationSettings()).authorizationStatus,
    );
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    if (!firebaseAvailable) return NotificationPermissionStatus.unavailable;
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return _mapStatus(settings.authorizationStatus);
  }

  @override
  Future<String?> getToken() async {
    if (!firebaseAvailable) return null;
    return _messaging.getToken();
  }

  @override
  Stream<String> get tokenRefreshes => firebaseAvailable
      ? _messaging.onTokenRefresh
      : const Stream<String>.empty();

  @override
  Stream<RemoteMessage> get foregroundMessages => firebaseAvailable
      ? FirebaseMessaging.onMessage
      : const Stream<RemoteMessage>.empty();

  @override
  Stream<RemoteMessage> get openedMessages => firebaseAvailable
      ? FirebaseMessaging.onMessageOpenedApp
      : const Stream<RemoteMessage>.empty();

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    if (!firebaseAvailable) return null;
    return _messaging.getInitialMessage();
  }

  NotificationPermissionStatus _mapStatus(
    AuthorizationStatus status,
  ) => switch (status) {
    AuthorizationStatus.authorized => NotificationPermissionStatus.authorized,
    AuthorizationStatus.provisional => NotificationPermissionStatus.provisional,
    AuthorizationStatus.denied => NotificationPermissionStatus.denied,
    AuthorizationStatus.notDetermined =>
      NotificationPermissionStatus.notDetermined,
  };
}
