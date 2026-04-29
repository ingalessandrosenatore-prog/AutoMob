import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/Exception/Exceptions.dart';
import '../models/app_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AppAuthUserModel> loginWithEmail(String email, String password);
  Future<AppAuthUserModel> loginWithGoogle();
  Future<AppAuthUserModel> loginWithApple();
  Future<AppAuthUserModel> signupWithEmail(
    String name,
    String email,
    String password,
      );
  Future<void> logout();
  Future<AppAuthUserModel?> checkSession();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<AppAuthUserModel> loginWithEmail(String email, String password) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthDataSourceException('Login fallito');
      }

      return AppAuthUserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw AuthDataSourceException(e.message, code: e.statusCode);
    } on SocketException {
      throw NetworkException('Errore di connessione');
    } catch (e) {
      throw AuthDataSourceException('Errore durante il login');
    }
  }

  @override
  Future<AppAuthUserModel> loginWithGoogle() async {
    try {
      final response = await supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
      );

      if (response == false) {
        throw AuthDataSourceException('Google login annullato');
      }

      final session = supabaseClient.auth.currentSession;
      if (session?.user == null) {
        throw AuthDataSourceException('Sessione non disponibile');
      }

      return AppAuthUserModel.fromSupabaseUser(session!.user);
    } on AuthException catch (e) {
      throw AuthDataSourceException(e.message, code: e.statusCode);
    } on SocketException {
      throw NetworkException('Errore di connessione');
    } catch (e) {
      throw AuthDataSourceException('Errore durante Google login');
    }
  }

  @override
  Future<AppAuthUserModel> loginWithApple() async {
    try {
      final response = await supabaseClient.auth.signInWithOAuth(
        OAuthProvider.apple,
      );

      if (response == false) {
        throw AuthDataSourceException('Apple login annullato');
      }

      final session = supabaseClient.auth.currentSession;
      if (session?.user == null) {
        throw AuthDataSourceException('Sessione non disponibile');
      }

      return AppAuthUserModel.fromSupabaseUser(session!.user);
    } on AuthException catch (e) {
      throw AuthDataSourceException(e.message, code: e.statusCode);
    } on SocketException {
      throw NetworkException('Errore di connessione');
    } catch (e) {
      throw AuthDataSourceException('Errore durante Apple login');
    }
  }

  @override
  Future<AppAuthUserModel> signupWithEmail(
    String name,
    String email,
    String password) async {
    try {
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': 'proprietario',
          'full_name': name,

        },
      );

      if (response.user == null) {
        throw AuthDataSourceException('Registrazione fallita');
      }

      return AppAuthUserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw AuthDataSourceException(e.message, code: e.statusCode);
    } on SocketException {
      throw NetworkException('Errore di connessione');
    } catch (e) {
      throw AuthDataSourceException('Errore durante la registrazione');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await supabaseClient.auth.signOut();
    } on SocketException {
      throw NetworkException('Errore di connessione');
    } catch (e) {
      throw AuthDataSourceException('Errore durante il logout');
    }
  }

  @override
  Future<AppAuthUserModel?> checkSession() async {
    try {
      final session = supabaseClient.auth.currentSession;
      return session?.user != null ? AppAuthUserModel.fromSupabaseUser(session!.user) : null;
    } on SocketException {
      throw NetworkException('Errore di connessione');
    } catch (e) {
      return null;
    }
  }
}