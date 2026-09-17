import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/mechanic_notification.dart';
import '../../domain/repositories/mechanic_notification_repository.dart';
import '../datasources/mechanic_notification_data_source.dart';

final class MechanicNotificationRepositoryImpl
    implements MechanicNotificationRepository {
  const MechanicNotificationRepositoryImpl(this.dataSource);
  final MechanicNotificationDataSource dataSource;

  @override
  Future<Either<Failure, NotificationSendResult>> send(
    MechanicNotification notification,
  ) async {
    try {
      return Right(await dataSource.send(notification));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
