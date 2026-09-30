import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/app_auth_user.dart';
import '../../domain/entities/italian_municipality.dart';
import '../../domain/entities/login_credentials.dart';
import '../../domain/entities/mechanic_registration.dart';
import '../../domain/entities/registration_outcome.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/municipality_local_data_source.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.municipalityDataSource,
  });

  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final MunicipalityLocalDataSource municipalityDataSource;

  @override
  Future<Either<Failure, AppAuthUser>> loginWithEmail(
    LoginCredentials credentials,
  ) async {
    try {
      final user = await remoteDataSource.loginWithEmail(credentials);
      await localDataSource.clearPendingVerificationEmail();
      return Right(user);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AuthDataException catch (error) {
      return Left(AuthFailure(_authMessage(error)));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, RegistrationOutcome>> registerMechanic(
    MechanicRegistration registration,
  ) async {
    try {
      final response = await remoteDataSource.registerMechanic(registration);
      if (response.requiresEmailConfirmation) {
        await localDataSource.savePendingVerificationEmail(registration.email);
        return Right(RegistrationConfirmationRequired(registration.email));
      }
      await localDataSource.clearPendingVerificationEmail();
      return Right(RegistrationAuthenticated(response.user));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AuthDataException catch (error) {
      return Left(AuthFailure(_authMessage(error)));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AppAuthUser?>> checkSession() async {
    try {
      final user = remoteDataSource.checkSession();
      if (user != null) await localDataSource.clearPendingVerificationEmail();
      return Right(user);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, String?>> getPendingVerificationEmail() async {
    try {
      return Right(localDataSource.getPendingVerificationEmail());
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<ItalianMunicipality>>> getMunicipalities() async {
    try {
      return Right(await municipalityDataSource.getMunicipalities());
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  String _authMessage(AuthDataException error) {
    return switch (error.code) {
      'invalid_credentials' => 'Email o password non corretti.',
      'user_already_exists' => 'Questa email è già registrata.',
      'weak_password' => 'La password deve contenere almeno 8 caratteri.',
      'over_email_send_rate_limit' =>
        'Troppi tentativi. Attendi qualche minuto e riprova.',
      _ => error.message,
    };
  }
}
