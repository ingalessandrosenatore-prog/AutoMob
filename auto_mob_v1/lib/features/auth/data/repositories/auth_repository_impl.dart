import 'package:fpdart/fpdart.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../core/error/exceptions/exception.dart';
import '../../../../core/error/exceptions/exceptions.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final Future<void> Function()? beforeLogout;

  AuthRepositoryImpl({required this.remoteDataSource, this.beforeLogout});

  @override
  Future<Either<Failure, AppAuthUser>> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      final authUser = await remoteDataSource.loginWithEmail(email, password);
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
  Future<Either<Failure, AppAuthUser>> signupWithEmail(
    String name,
    String email,
    String password,
  ) async {
    try {
      final authUser = await remoteDataSource.signupWithEmail(
        name,
        email,
        password,
      );
      return Right(authUser);
    } on AuthDataSourceException catch (e) {
      return Left(_mapAuthException(e));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
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
      return Right(authUser);
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  // Helper method per mappare le eccezioni auth in failure specifiche
  Failure _mapAuthException(AuthDataSourceException e) {
    switch (e.code) {
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
