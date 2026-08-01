import 'package:fpdart/fpdart.dart';
import '../entities/signup_outcome.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/exceptions/exception.dart';

class SignupWithEmail {
  final AuthRepository repository;

  SignupWithEmail(this.repository);

  Future<Either<Failure, SignupOutcome>> call(
    String name,
    String email,
    String password,
  ) {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedName.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Inserisci il tuo nome.')),
      );
    }
    if (!_emailPattern.hasMatch(normalizedEmail)) {
      return Future.value(
        const Left(ValidationFailure('Inserisci un indirizzo email valido.')),
      );
    }
    if (password.length < 8) {
      return Future.value(const Left(WeakPasswordFailure()));
    }

    return repository.signupWithEmail(
      normalizedName,
      normalizedEmail,
      password,
    );
  }

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
}
