import 'package:fpdart/fpdart.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/signup_outcome.dart';
import '../../domain/entities/pending_email_verification.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../core/error/exceptions/exception.dart';
import '../../../../core/error/exceptions/exceptions.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final Future<void> Function()? beforeLogout;
  final DateTime Function() now;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    this.beforeLogout,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  @override
  Future<Either<Failure, AppAuthUser>> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      final authUser = await remoteDataSource.loginWithEmail(email, password);
      await localDataSource.clearPendingVerificationEmail();
      return Right(authUser);
    } on EmailNotConfirmedException {
      return const Left(EmailNotConfirmedFailure());
    } on AuthDataSourceException catch (e) {
      return Left(_mapAuthException(e));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AppAuthUser>> loginWithGoogle() async {
    try {
      final authUser = await remoteDataSource.loginWithGoogle();
      await localDataSource.clearPendingVerificationEmail();
      return Right(authUser);
    } on AuthDataSourceException catch (e) {
      if (e.message.contains('annullato')) {
        return const Left(AuthCancelledFailure());
      }
      return Left(_mapAuthException(e));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AppAuthUser>> loginWithApple() async {
    try {
      final authUser = await remoteDataSource.loginWithApple();
      await localDataSource.clearPendingVerificationEmail();
      return Right(authUser);
    } on AuthDataSourceException catch (e) {
      if (e.message.contains('annullato')) {
        return const Left(AuthCancelledFailure());
      }
      return Left(_mapAuthException(e));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, SignupOutcome>> signupWithEmail(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await remoteDataSource.signupWithEmail(
        name,
        email,
        password,
      );
      if (response.requiresEmailConfirmation) {
        final sentAt = now();
        await localDataSource.savePendingEmailVerification(email, sentAt);
        return Right(
          SignupConfirmationRequired(
            PendingEmailVerification(email: email, lastSentAt: sentAt),
          ),
        );
      }
      await localDataSource.clearPendingVerificationEmail();
      return Right(SignupAuthenticated(response.user));
    } on AuthDataSourceException catch (e) {
      return Left(_mapAuthException(e));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, PendingEmailVerification?>>
  getPendingEmailVerification() async {
    try {
      final pending = await localDataSource.getPendingEmailVerification();
      return Right(
        pending == null
            ? null
            : PendingEmailVerification(
                email: pending.email,
                lastSentAt: pending.lastSentAt,
              ),
      );
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> resendConfirmationEmail(String email) async {
    try {
      await remoteDataSource.resendConfirmationEmail(email);
      await localDataSource.savePendingEmailVerification(email, now());
      return const Right(null);
    } on AuthDataSourceException catch (e) {
      return Left(_mapAuthException(e));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> clearPendingEmailVerification() async {
    try {
      await localDataSource.clearPendingVerificationEmail();
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Un errore FCM non deve impedire il logout. La funzione e' opzionale
      // per mantenere il repository facilmente testabile.
      try {
        await beforeLogout?.call();
      } catch (_) {}
      await remoteDataSource.logout();
      return const Right(null);
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AppAuthUser?>> checkSession() async {
    try {
      final authUser = await remoteDataSource.checkSession();
      if (authUser != null) {
        await localDataSource.clearPendingVerificationEmail();
      }
      return Right(authUser);
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Stream<Either<Failure, AppAuthUser>> observeAuthenticatedUsers() async* {
    try {
      await for (final user in remoteDataSource.observeAuthenticatedUsers()) {
        await localDataSource.clearPendingVerificationEmail();
        yield Right(user);
      }
    } catch (_) {
      yield const Left(ServerFailure());
    }
  }

  // Helper method per mappare le eccezioni auth in failure specifiche
  Failure _mapAuthException(AuthDataSourceException e) {
    switch (e.code) {
      case 'over_email_send_rate_limit':
        return const AuthFailure(
          'Limite di invio raggiunto. Usa una delle email gia ricevute '
          'oppure riprova piu tardi.',
        );
      case '400':
        if (e.message.contains('password')) {
          return const WeakPasswordFailure();
        }
        break;
      case '422':
        if (e.message.contains('email')) {
          return const EmailAlreadyInUseFailure();
        }
        break;
      case '401':
        return const AuthFailure('Email o password errati');
      default:
        break;
    }

    // Se contiene messaggi specifici
    if (e.message.contains('già registrata')) {
      return const EmailAlreadyInUseFailure();
    }

    if (e.message.contains('password')) {
      return const WeakPasswordFailure();
    }

    // Default auth failure con messaggio
    return AuthFailure(e.message);
  }
}
