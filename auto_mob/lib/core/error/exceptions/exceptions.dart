class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Errore di cache locale']);

  @override
  String toString() => 'CacheException: $message';
}

class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Errore server']);

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Errore di connessione']);

  @override
  String toString() => 'NetworkException: $message';
}

class AuthDataSourceException implements Exception {
  final String message;
  final String? code;
  const AuthDataSourceException(this.message, {this.code});

  @override
  String toString() => 'AuthDataSourceException($code): $message';
}

/// Login rifiutato perche' l'email non e' ancora stata confermata.
/// Isolata da [AuthDataSourceException] perche' Supabase la segnala con un
/// `code` semantico dedicato ('email_not_confirmed'), distinto dallo status
/// HTTP generico che [AuthDataSourceException.code] gia' porta con se'.
class EmailNotConfirmedException implements Exception {
  const EmailNotConfirmedException();

  @override
  String toString() => 'EmailNotConfirmedException';
}

class VehicleDataSourceException implements Exception {
  final String message;
  final String? code;
  const VehicleDataSourceException(this.message, {this.code});

  @override
  String toString() => 'VehicleDataSourceException($code): $message';
}

class WorkLogDataSourceException implements Exception {
  final String message;
  final String? code;
  const WorkLogDataSourceException(this.message, {this.code});

  @override
  String toString() => 'WorkLogDataSourceException($code): $message';
}
