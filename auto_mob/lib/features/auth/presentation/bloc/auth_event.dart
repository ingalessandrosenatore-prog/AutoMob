import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';

sealed class AuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

// Evento per controllare la sessione all'avvio
class CheckSessionEvent extends AuthEvent {}

// Eventi di login
class LoginWithEmailEvent extends AuthEvent {
  final String email;
  final String password;

  LoginWithEmailEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class LoginWithGoogleEvent extends AuthEvent {}

class LoginWithAppleEvent extends AuthEvent {}

// Eventi di registrazione
class SignupWithEmailEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String? phone;

  SignupWithEmailEvent({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });

  @override
  List<Object> get props => [name, email, password, phone ?? ''];
}

class ResendConfirmationEmailEvent extends AuthEvent {
  ResendConfirmationEmailEvent({required this.email});

  final String email;

  @override
  List<Object> get props => [email];
}

class CheckEmailConfirmationEvent extends AuthEvent {}

class LeaveEmailVerificationEvent extends AuthEvent {}

class AuthSessionEstablishedEvent extends AuthEvent {
  AuthSessionEstablishedEvent({required this.user});

  final AppAuthUser user;

  @override
  List<Object> get props => [user];
}

// Evento di logout
class LogoutEvent extends AuthEvent {}

// Eventi di navigazione (non richiedono API call)
class GoToLoginEvent extends AuthEvent {}

class GoToRegistrationEvent extends AuthEvent {}
