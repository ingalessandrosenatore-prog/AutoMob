import 'package:fpdart/fpdart.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/exceptions/exception.dart';

class CheckSession {
  final AuthRepository repository;

  CheckSession(this.repository);

  Future<Either<Failure, AppAuthUser?>> call() {
    return repository.checkSession();
  }
}
