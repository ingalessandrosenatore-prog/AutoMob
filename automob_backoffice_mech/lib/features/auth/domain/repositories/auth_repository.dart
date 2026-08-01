import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_auth_user.dart';
import '../entities/italian_municipality.dart';
import '../entities/mechanic_registration.dart';
import '../entities/registration_outcome.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, RegistrationOutcome>> registerMechanic(
    MechanicRegistration registration,
  );

  Future<Either<Failure, AppAuthUser?>> checkSession();

  Future<Either<Failure, String?>> getPendingVerificationEmail();

  Future<Either<Failure, List<ItalianMunicipality>>> getMunicipalities();
}
