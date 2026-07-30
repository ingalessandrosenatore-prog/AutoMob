import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/notification_permission_status.dart';
import '../repositories/notification_repository.dart';

class RequestNotificationPermission {
  const RequestNotificationPermission(this.repository);

  final NotificationRepository repository;

  Future<Either<Failure, NotificationPermissionStatus>> call() =>
      repository.requestPermission();
}
