import 'package:equatable/equatable.dart';

final class LoginCredentials extends Equatable {
  const LoginCredentials({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
