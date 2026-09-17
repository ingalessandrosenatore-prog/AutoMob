import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions/exception.dart';
import '../entities/owner_registration.dart';

abstract interface class OwnerAccessRepository {
  Future<Either<Failure, OwnerAccess>> resolve({
    OwnerRegistration? registration,
  });
}
