import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../repositories/auth_repository.dart';

class ResendConfirmationEmail {
  ResendConfirmationEmail(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, void>> call(String email) {
    return repository.resendConfirmationEmail(email);
  }
}
