import 'package:equatable/equatable.dart';

sealed class VehicleLookupFailure extends Equatable {
  final String message;
  const VehicleLookupFailure(this.message);

  bool get isRetryable => false;
  bool get consumesAttempt => true;

  @override
  List<Object> get props => [message];
}

class InvalidPlateLookupFailure extends VehicleLookupFailure {
  const InvalidPlateLookupFailure()
    : super('La targa deve avere il formato AA123AA.');
  @override
  bool get consumesAttempt => false;
}

class NetworkLookupFailure extends VehicleLookupFailure {
  const NetworkLookupFailure()
    : super('Connessione assente. Controlla la rete e riprova.');
  @override
  bool get isRetryable => true;
  @override
  bool get consumesAttempt => false;
}

class TimeoutLookupFailure extends VehicleLookupFailure {
  const TimeoutLookupFailure()
    : super('Il servizio non ha risposto in tempo. Puoi riprovare.');
  @override
  bool get isRetryable => true;
  @override
  bool get consumesAttempt => false;
}

class BadRequestLookupFailure extends VehicleLookupFailure {
  const BadRequestLookupFailure()
    : super('Targa errata oppure dati non disponibili.');
}

class UnauthorizedLookupFailure extends VehicleLookupFailure {
  const UnauthorizedLookupFailure() : super('Servizio targa non autorizzato.');
}

class ForbiddenLookupFailure extends VehicleLookupFailure {
  const ForbiddenLookupFailure() : super('Accesso al servizio targa negato.');
}

class RateLimitedLookupFailure extends VehicleLookupFailure {
  const RateLimitedLookupFailure()
    : super('Limite di richieste raggiunto. Inserisci i dati a mano.');
}

class ServerLookupFailure extends VehicleLookupFailure {
  const ServerLookupFailure()
    : super('Il servizio targa non è disponibile. Inserisci i dati a mano.');
}

class NoDataLookupFailure extends VehicleLookupFailure {
  const NoDataLookupFailure() : super('Nessun dato disponibile per la targa.');
}

class MalformedResponseLookupFailure extends VehicleLookupFailure {
  const MalformedResponseLookupFailure()
    : super('Il servizio ha restituito una risposta non valida.');
}
