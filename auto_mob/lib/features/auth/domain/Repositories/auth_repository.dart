import 'package:fpdart/fpdart.dart';
import '../entities/app_user.dart';
import '../entities/signup_outcome.dart';
import '../entities/pending_email_verification.dart';
import '../../../../core/error/exceptions/exception.dart';

abstract class AuthRepository {
  Future<Either<Failure, AppAuthUser>> loginWithEmail(
    String email,
    String password,
  );
  Future<Either<Failure, AppAuthUser>> loginWithGoogle();
  Future<Either<Failure, AppAuthUser>> loginWithApple();
  Future<Either<Failure, SignupOutcome>> signupWithEmail(
    String name,
    String email,
    String password,
  );
  Future<Either<Failure, PendingEmailVerification?>>
  getPendingEmailVerification();
  Future<Either<Failure, void>> resendConfirmationEmail(String email);
  Future<Either<Failure, void>> clearPendingEmailVerification();
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, AppAuthUser?>> checkSession();
  Stream<Either<Failure, AppAuthUser>> observeAuthenticatedUsers();
}
