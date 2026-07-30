/// Stato del permesso push, indipendente dai tipi Firebase.
/// Il domain resta cosi' testabile senza importare plugin Flutter.
enum NotificationPermissionStatus {
  unavailable,
  notDetermined,
  denied,
  authorized,
  provisional;

  bool get canReceiveNotifications => this == authorized || this == provisional;
}
