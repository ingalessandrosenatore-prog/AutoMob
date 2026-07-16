import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../repositories/notification_repository.dart';

class UnregisterDeviceToken {
  const UnregisterDeviceToken(this.repository);

  final NotificationRepository repository;

  Future<Either<Failure, void>> call() => repository.unregisterCurrentDevice();
}
