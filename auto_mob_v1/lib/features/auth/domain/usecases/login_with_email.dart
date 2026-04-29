import 'package:fpdart/fpdart.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/Exception/Exception.dart';

class LoginWithEmail {
  final AuthRepository repository;

  LoginWithEmail(this.repository);

  Future<Either<Failure, AppAuthUser>> call(String email, String password) {
    return repository.loginWithEmail(email, password);
  }
}