import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/mechanic_notification.dart';

abstract interface class MechanicNotificationRepository {
  Future<Either<Failure, NotificationSendResult>> send(
    MechanicNotification notification,
  );
}
