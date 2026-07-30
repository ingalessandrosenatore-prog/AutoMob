import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../repositories/notification_repository.dart';

class PostponeNotificationPermission {
  const PostponeNotificationPermission(this.repository);

  final NotificationRepository repository;

  Future<Either<Failure, void>> call() => repository.postponePermissionPrompt();
}
