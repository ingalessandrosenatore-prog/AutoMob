import 'package:equatable/equatable.dart';

class AppAuthUser extends Equatable {
  final String id;
  final String email;
  final String displayName;

  const AppAuthUser({
    required this.id,
    required this.email,
    this.displayName = '',
  });

  String get homeLabel => displayName.trim().isEmpty ? email : displayName;

  @override
  List<Object> get props => [id, email, displayName];
}
