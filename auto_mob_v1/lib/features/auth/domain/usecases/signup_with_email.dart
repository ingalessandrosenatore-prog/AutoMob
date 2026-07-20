import 'package:fpdart/fpdart.dart';
import '../entities/signup_outcome.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/exceptions/exception.dart';

class SignupWithEmail {
  final AuthRepository repository;

  SignupWithEmail(this.repository);

  Future<Either<Failure, SignupOutcome>> call(
    String name,
    String email,
    String password,
  ) {
    return repository.signupWithEmail(name, email, password);
  }
}
