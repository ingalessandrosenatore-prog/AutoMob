import 'dart:async';

import '../../domain/entities/notification_message.dart';
import '../../domain/usecases/observe_notification_messages.dart';
import '../../domain/usecases/register_device_token.dart';

typedef NotificationMessageCallback =
    void Function(Map<String, dynamic> data, String? title, String? body);

/// Collega gli stream FCM all'app. Non contiene logica di scadenza: quella
/// rimane su Supabase anche quando AutoMob e' chiusa.
class NotificationMessageCoordinator {
  NotificationMessageCoordinator({
    required this.messages,
    required this.registerDeviceToken,
  });

  final ObserveNotificationMessages messages;
  final RegisterDeviceToken registerDeviceToken;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  Future<void> start({
    required NotificationMessageCallback onOpened,
    required NotificationMessageCallback onForeground,
  }) async {
    if (!messages.isAvailable) return;

    // Se la sessione Supabase e il permesso esistono gia', rinnova last_seen.
    await registerDeviceToken();

    _subscriptions.add(
      messages.tokenRefreshes.listen((_) => registerDeviceToken()),
    );
    _subscriptions.add(
      messages.foregroundMessages.listen(
        (message) => _notify(onForeground, message),
      ),
    );
    _subscriptions.add(
      messages.openedMessages.listen((message) => _notify(onOpened, message)),
    );

    final initial = await messages.initialMessage();
    if (initial != null) _notify(onOpened, initial);
  }

  void _notify(
    NotificationMessageCallback callback,
    NotificationMessage message,
  ) {
    callback(message.data, message.title, message.body);
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }
}
