import 'package:equatable/equatable.dart';

class AppAuthUser extends Equatable {
  final String id;
  final String email;

  const AppAuthUser({required this.id, required this.email});

  @override
  List<Object> get props => [id, email];
}
