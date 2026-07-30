import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../repositories/notification_repository.dart';

class ShouldOfferNotificationPermission {
  const ShouldOfferNotificationPermission(this.repository);

  final NotificationRepository repository;

  Future<Either<Failure, bool>> call() => repository.shouldOfferPermission();
}
