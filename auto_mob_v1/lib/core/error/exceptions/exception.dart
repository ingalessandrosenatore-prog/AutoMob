import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

// Errori di rete/connessione
class NetworkFailure extends Failure {
  const NetworkFailure()
    : super("Connessione assente. Controlla la rete e riprova.");
}

// Errori server generici
class ServerFailure extends Failure {
  const ServerFailure()
    : super("Si � verificato un errore. Riprova tra qualche istante.");
}

class CodedServerFailure extends ServerFailure {
  final String? code;

  const CodedServerFailure({this.code});

  @override
  List<Object> get props => [message, ?code];
}

// Risorsa non trovata
class NotFoundFailure extends Failure {
  const NotFoundFailure() : super("Risorsa non trovata.");
}

// Input non valido
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

// Errori di autenticazione
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class AuthCancelledFailure extends Failure {
  const AuthCancelledFailure() : super("Accesso annullato.");
}

class EmailNotConfirmedFailure extends Failure {
  const EmailNotConfirmedFailure()
    : super("Non hai verificato la tua email. Verifica e riprova.");
}

class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure()
    : super("Questa email � gi� registrata. Effettua il login.");
}

class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure()
    : super("La password � troppo debole. Usa almeno 8 caratteri.");
}

// Permessi
class PermissionFailure extends Failure {
  const PermissionFailure()
    : super("Non hai il permesso di accedere a questa risorsa.");
}

// Duplicati
class DuplicateFailure extends Failure {
  const DuplicateFailure(super.message);
}

// Storage locale
class StorageFailure extends Failure {
  const StorageFailure()
    : super("Impossibile salvare il file sul dispositivo.");
}

// Regole di business
class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure(super.message);
}
