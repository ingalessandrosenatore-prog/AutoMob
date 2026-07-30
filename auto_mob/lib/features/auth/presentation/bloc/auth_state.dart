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

enum EmailVerificationStatus { idle, resending, resent, checking, error }

class AuthEmailVerificationPending extends AuthState {
  AuthEmailVerificationPending({
    required this.email,
    this.countdownSeconds = 120,
    this.status = EmailVerificationStatus.idle,
    this.message,
  });

  final String email;
  final int countdownSeconds;
  final EmailVerificationStatus status;
  final String? message;

  bool get isBusy =>
      status == EmailVerificationStatus.resending ||
      status == EmailVerificationStatus.checking;

  AuthEmailVerificationPending copyWith({
    EmailVerificationStatus? status,
    int? countdownSeconds,
    String? message,
    bool clearMessage = false,
  }) {
    return AuthEmailVerificationPending(
      email: email,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      status: status ?? this.status,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [email, countdownSeconds, status, message];
}

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
