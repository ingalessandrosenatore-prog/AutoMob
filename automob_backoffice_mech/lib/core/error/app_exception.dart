sealed class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;
}

final class AuthDataException extends AppException {
  const AuthDataException(super.message, {super.code});
}

final class NetworkException extends AppException {
  const NetworkException() : super('Errore di connessione');
}

final class WorkshopDataException extends AppException {
  const WorkshopDataException(super.message, {super.code});
}
