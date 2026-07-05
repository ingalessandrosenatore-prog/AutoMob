import 'package:fpdart/fpdart.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/exceptions/exception.dart';

class LoginWithGoogle {
  final AuthRepository repository;

  LoginWithGoogle(this.repository);

  Future<Either<Failure, AppAuthUser>> call() {
    return repository.loginWithGoogle();
  }
}
