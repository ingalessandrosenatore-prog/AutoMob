import 'package:fpdart/fpdart.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/exceptions/exception.dart';

class Logout {
  final AuthRepository repository;

  Logout(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.logout();
  }
}
