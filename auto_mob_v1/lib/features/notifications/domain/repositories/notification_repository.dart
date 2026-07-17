import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/notification_message.dart';
import '../entities/notification_permission_status.dart';

abstract interface class NotificationRepository {
  bool get messagingAvailable;

  Stream<void> get tokenRefreshes;

  Stream<NotificationMessage> get foregroundMessages;

  Stream<NotificationMessage> get openedMessages;

  Future<NotificationMessage?> initialMessage();

  Future<Either<Failure, bool>> shouldOfferPermission();

  Future<Either<Failure, NotificationPermissionStatus>> requestPermission();

  Future<Either<Failure, void>> postponePermissionPrompt();

  Future<Either<Failure, void>> registerCurrentDevice();

  Future<Either<Failure, void>> unregisterCurrentDevice();
}
