import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../data/datasources/firebase_messaging_data_source.dart';
import '../../domain/usecases/register_device_token.dart';

typedef NotificationMessageCallback =
    void Function(Map<String, dynamic> data, String? title, String? body);

/// Collega gli stream FCM all'app. Non contiene logica di scadenza: quella
/// rimane su Supabase anche quando AutoMob e' chiusa.
class NotificationMessageCoordinator {
  NotificationMessageCoordinator({
    required this.messaging,
    required this.registerDeviceToken,
  });

  final FirebaseMessagingDataSource messaging;
  final RegisterDeviceToken registerDeviceToken;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  Future<void> start({
    required NotificationMessageCallback onOpened,
    required NotificationMessageCallback onForeground,
  }) async {
    if (!messaging.isAvailable) return;

    // Se la sessione Supabase e il permesso esistono gia', rinnova last_seen.
    await registerDeviceToken();

    _subscriptions.add(
      messaging.tokenRefreshes.listen((_) => registerDeviceToken()),
    );
    _subscriptions.add(
      messaging.foregroundMessages.listen(
        (message) => _notify(onForeground, message),
      ),
    );
    _subscriptions.add(
      messaging.openedMessages.listen((message) => _notify(onOpened, message)),
    );

    final initial = await messaging.getInitialMessage();
    if (initial != null) _notify(onOpened, initial);
  }

  void _notify(NotificationMessageCallback callback, RemoteMessage message) {
    callback(
      Map<String, dynamic>.from(message.data),
      message.notification?.title,
      message.notification?.body,
    );
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }
}
