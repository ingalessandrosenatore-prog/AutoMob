sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure()
    : super('Connessione assente. Controlla la rete e riprova.');
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class ServerFailure extends Failure {
  const ServerFailure()
    : super('Si è verificato un errore. Riprova tra qualche istante.');
}

final class PermissionFailure extends Failure {
  const PermissionFailure()
    : super('Non hai il permesso di accedere a questa risorsa.');
}
