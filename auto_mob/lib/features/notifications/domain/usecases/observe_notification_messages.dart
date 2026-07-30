import '../entities/notification_message.dart';
import '../repositories/notification_repository.dart';

/// Espone alla presentation gli eventi push senza farle conoscere Firebase.
class ObserveNotificationMessages {
  const ObserveNotificationMessages(this.repository);

  final NotificationRepository repository;

  bool get isAvailable => repository.messagingAvailable;

  Stream<void> get tokenRefreshes => repository.tokenRefreshes;

  Stream<NotificationMessage> get foregroundMessages =>
      repository.foregroundMessages;

  Stream<NotificationMessage> get openedMessages => repository.openedMessages;

  Future<NotificationMessage?> initialMessage() => repository.initialMessage();
}
