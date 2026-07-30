import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../repositories/auth_repository.dart';

class LeaveEmailVerification {
  LeaveEmailVerification(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, void>> call() {
    return repository.clearPendingEmailVerification();
  }
}
