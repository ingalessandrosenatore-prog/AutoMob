import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/pending_email_verification.dart';
import '../repositories/auth_repository.dart';

class GetPendingVerificationEmail {
  GetPendingVerificationEmail(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, PendingEmailVerification?>> call() {
    return repository.getPendingEmailVerification();
  }
}
