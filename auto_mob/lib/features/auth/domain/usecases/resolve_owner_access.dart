import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions/exception.dart';
import '../entities/owner_registration.dart';
import '../repositories/owner_access_repository.dart';

class ResolveOwnerAccess {
  const ResolveOwnerAccess(this.repository);
  final OwnerAccessRepository repository;

  Future<Either<Failure, OwnerAccess>> call({OwnerRegistration? registration}) {
    final error = registration?.validate();
    if (error != null) return Future.value(Left(ValidationFailure(error)));
    return repository.resolve(registration: registration);
  }
}
