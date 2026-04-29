import 'package:fpdart/fpdart.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/Exception/Exception.dart';

class SignupWithEmail {
  final AuthRepository repository;

  SignupWithEmail(this.repository);

  Future<Either<Failure, AppAuthUser>> call(
    String name,
    String email,
    String password,
  ) {
    return repository.signupWithEmail(name, email, password);
  }
}