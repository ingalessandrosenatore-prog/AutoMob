import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../repositories/auth_repository.dart';

final class GetPendingVerificationEmail {
  const GetPendingVerificationEmail(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, String?>> call() =>
      repository.getPendingVerificationEmail();
}
