import 'package:fpdart/fpdart.dart';
import '../entities/app_user.dart';
import '../../../../core/error/Exception/Exception.dart';

abstract class AuthRepository {
  Future<Either<Failure, AppAuthUser>> loginWithEmail(String email, String password);
  Future<Either<Failure, AppAuthUser>> loginWithGoogle();
  Future<Either<Failure, AppAuthUser>> loginWithApple();
  Future<Either<Failure, AppAuthUser>> signupWithEmail(
    String name,
    String email,
    String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, AppAuthUser?>> checkSession();
}