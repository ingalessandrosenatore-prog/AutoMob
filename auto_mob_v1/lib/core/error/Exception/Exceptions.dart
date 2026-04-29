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

class VehicleDataSourceException implements Exception {
  final String message;
  final String? code;
  const VehicleDataSourceException(this.message, {this.code});

  @override
  String toString() => 'VehicleDataSourceException($code): $message';
}
