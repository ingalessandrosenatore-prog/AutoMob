enum MechanicNotificationType {
  distribution(
    'distribuzione',
    'Distribuzione',
    'Controllo distribuzione',
    'La tua auto ha bisogno di un controllo della distribuzione. Contattaci per programmare l’intervento.',
  ),
  service(
    'tagliando',
    'Tagliando',
    'È il momento del tagliando',
    'La tua auto ha bisogno del tagliando. Contattaci per concordare un appuntamento.',
  ),
  tireChange(
    'pneumatici_cambio',
    'Cambio gomme',
    'Cambio gomme',
    'La tua auto ha bisogno del cambio gomme. Contattaci per scegliere gli pneumatici e fissare un appuntamento.',
  ),
  tireRotation(
    'pneumatici_inversione',
    'Rotazione gomme',
    'Rotazione gomme',
    'È il momento di ruotare gli pneumatici della tua auto per favorire un’usura uniforme. Contattaci per un appuntamento.',
  );

  const MechanicNotificationType(this.code, this.label, this.title, this.body);
  final String code;
  final String label;
  final String title;
  final String body;
}

final class MechanicNotification {
  const MechanicNotification({
    required this.vehicleId,
    required this.requestId,
    required this.type,
    required this.title,
    required this.body,
  });
  final String vehicleId;
  final String requestId;
  final MechanicNotificationType type;
  final String title;
  final String body;
}

enum NotificationSendResult { sent, pending, noDevice, failed }
