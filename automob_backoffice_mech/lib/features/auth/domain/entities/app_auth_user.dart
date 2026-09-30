import 'package:equatable/equatable.dart';

base class AppAuthUser extends Equatable {
  const AppAuthUser({required this.id, required this.email});

  final String id;
  final String email;

  @override
  List<Object?> get props => [id, email];
}
