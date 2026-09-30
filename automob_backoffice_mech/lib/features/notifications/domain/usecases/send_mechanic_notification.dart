import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/mechanic_notification.dart';
import '../repositories/mechanic_notification_repository.dart';

final class SendMechanicNotification {
  const SendMechanicNotification(this.repository);
  final MechanicNotificationRepository repository;

  Future<Either<Failure, NotificationSendResult>> call(
    MechanicNotification draft,
  ) {
    final title = draft.title.trim();
    final body = draft.body.trim();
    if (draft.vehicleId.isEmpty ||
        draft.requestId.isEmpty ||
        title.isEmpty ||
        body.isEmpty ||
        title.length > 100 ||
        body.length > 500) {
      return Future.value(
        const Left(
          ValidationFailure(
            'Inserisci un titolo (massimo 100 caratteri) e un messaggio (massimo 500 caratteri).',
          ),
        ),
      );
    }
    return repository.send(
      MechanicNotification(
        vehicleId: draft.vehicleId,
        requestId: draft.requestId,
        type: draft.type,
        title: title,
        body: body,
      ),
    );
  }
}
