/// Messaggio push indipendente da Firebase.
///
/// Il tipo infrastrutturale `RemoteMessage` resta confinato nel data layer.
final class NotificationMessage {
  const NotificationMessage({required this.data, this.title, this.body});

  final Map<String, dynamic> data;
  final String? title;
  final String? body;
}
