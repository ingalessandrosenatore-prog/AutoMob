import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_auth_user.dart';
import '../entities/login_credentials.dart';
import '../repositories/auth_repository.dart';

final class LoginWithEmail {
  const LoginWithEmail(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, AppAuthUser>> call(LoginCredentials credentials) =>
      repository.loginWithEmail(credentials);
}
