import 'package:equatable/equatable.dart';
import '../../domain/entities/app_user.dart';

sealed class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Stato iniziale - loading del check session
class AuthInitial extends AuthState {}

// Stati di loading
class AuthLoading extends AuthState {}

// Stati di successo
class AuthAuthenticated extends AuthState {
  final AppAuthUser user;

  AuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

// Stati di errore
class AuthError extends AuthState {
  final String message;

  /// True quando il login e' stato rifiutato perche' l'email non e' ancora
  /// stata confermata: la UI mostra un pop-up dedicato con "Riprova" invece
  /// del banner d'errore generico.
  final bool emailNotConfirmed;

  AuthError({required this.message, this.emailNotConfirmed = false});

  @override
  List<Object> get props => [message, emailNotConfirmed];
}

// Stato di logout completato
class AuthLoggedOut extends AuthState {}