import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_auth_user.dart';
import '../repositories/auth_repository.dart';

final class CheckAuthSession {
  const CheckAuthSession(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, AppAuthUser?>> call() => repository.checkSession();
}
