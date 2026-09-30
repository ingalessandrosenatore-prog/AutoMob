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
    String passwordConfirmation,
    String phone,
    String postalCode,
  ) {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = phone.trim();
    final normalizedPostalCode = postalCode.trim();

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
    if (password != passwordConfirmation) {
      return Future.value(
        const Left(ValidationFailure('Le password non coincidono.')),
      );
    }
    final phoneDigits = normalizedPhone.replaceAll(RegExp('[^0-9]'), '');
    if (phoneDigits.length < 8 || phoneDigits.length > 15) {
      return Future.value(
        const Left(
          ValidationFailure('Inserisci un numero di telefono valido.'),
        ),
      );
    }
    if (!_postalCodePattern.hasMatch(normalizedPostalCode)) {
      return Future.value(
        const Left(ValidationFailure('Inserisci un CAP italiano valido.')),
      );
    }

    return repository.signupWithEmail(
      normalizedName,
      normalizedEmail,
      password,
      normalizedPhone,
      normalizedPostalCode,
    );
  }

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _postalCodePattern = RegExp(r'^\d{5}$');
}
