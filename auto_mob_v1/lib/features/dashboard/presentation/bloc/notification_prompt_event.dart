import 'package:equatable/equatable.dart';

sealed class NotificationPromptEvent extends Equatable {
  const NotificationPromptEvent();

  @override
  List<Object?> get props => [];
}

/// La dashboard comunica soltanto il dato che possiede: se esiste almeno un
/// veicolo reale. Il BLoC decide poi se il prompt debba essere mostrato.
final class NotificationPromptCheckRequested extends NotificationPromptEvent {
  const NotificationPromptCheckRequested({required this.hasRealVehicles});

  final bool hasRealVehicles;

  @override
  List<Object?> get props => [hasRealVehicles];
}

final class NotificationPromptPostponeRequested
    extends NotificationPromptEvent {
  const NotificationPromptPostponeRequested();
}

final class NotificationPromptEnableRequested extends NotificationPromptEvent {
  const NotificationPromptEnableRequested();
}

/// Un altro effetto della dashboard ha dovuto chiudere il dialogo prima che
/// l'utente scegliesse. Riporta il workflow a Initial per poterlo rivalutare.
final class NotificationPromptOfferInterrupted extends NotificationPromptEvent {
  const NotificationPromptOfferInterrupted();
}
