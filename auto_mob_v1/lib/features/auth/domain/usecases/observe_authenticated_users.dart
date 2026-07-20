import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class ObserveAuthenticatedUsers {
  ObserveAuthenticatedUsers(this.repository);

  final AuthRepository repository;

  Stream<Either<Failure, AppAuthUser>> call() {
    return repository.observeAuthenticatedUsers();
  }
}
