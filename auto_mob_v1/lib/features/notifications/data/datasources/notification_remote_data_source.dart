import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRemoteDataSourceException implements Exception {
  const NotificationRemoteDataSourceException(this.message);

  final String message;
}

abstract interface class NotificationRemoteDataSource {
  Future<void> registerToken({required String token, required String platform});

  Future<void> unregisterToken(String token);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl(this.supabaseClient);

  final SupabaseClient supabaseClient;

  @override
  Future<void> registerToken({
    required String token,
    required String platform,
  }) async {
    await _invoke({'action': 'register', 'token': token, 'platform': platform});
  }

  @override
  Future<void> unregisterToken(String token) async {
    await _invoke({'action': 'unregister', 'token': token});
  }

  Future<void> _invoke(Map<String, dynamic> body) async {
    if (supabaseClient.auth.currentUser == null) {
      throw const NotificationRemoteDataSourceException(
        'Utente non autenticato',
      );
    }
    final response = await supabaseClient.functions.invoke(
      'device-token',
      body: body,
    );
    if (response.status < 200 || response.status >= 300) {
      throw NotificationRemoteDataSourceException(
        'Edge Function device-token: ${response.status}',
      );
    }
  }
}
