import 'package:fpdart/fpdart.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/exceptions/exception.dart';

class LoginWithGoogle {
  final AuthRepository repository;

  LoginWithGoogle(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.loginWithGoogle();
  }
}
