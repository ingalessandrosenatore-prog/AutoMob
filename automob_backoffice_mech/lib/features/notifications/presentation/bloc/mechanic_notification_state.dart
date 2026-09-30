import '../../domain/entities/mechanic_notification.dart';

final class MechanicNotificationState {
  const MechanicNotificationState({
    this.type = MechanicNotificationType.distribution,
    this.title = 'Controllo distribuzione',
    this.body =
        'La tua auto ha bisogno di un controllo della distribuzione. Contattaci per programmare l’intervento.',
    this.sending = false,
    this.result,
    this.error,
  });
  final MechanicNotificationType type;
  final String title;
  final String body;
  final bool sending;
  final NotificationSendResult? result;
  final String? error;
  bool get canSend =>
      !sending &&
      result != NotificationSendResult.sent &&
      title.trim().isNotEmpty &&
      body.trim().isNotEmpty;

  MechanicNotificationState copyWith({
    MechanicNotificationType? type,
    String? title,
    String? body,
    bool? sending,
    NotificationSendResult? result,
    String? error,
  }) => MechanicNotificationState(
    type: type ?? this.type,
    title: title ?? this.title,
    body: body ?? this.body,
    sending: sending ?? this.sending,
    result: result,
    error: error,
  );
}
