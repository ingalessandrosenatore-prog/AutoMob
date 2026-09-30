import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/mechanic_registration.dart';
import '../entities/registration_outcome.dart';
import '../repositories/auth_repository.dart';

final class RegisterMechanic {
  const RegisterMechanic(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, RegistrationOutcome>> call(
    MechanicRegistration registration,
  ) => repository.registerMechanic(registration);
}
