import '../../domain/entities/italian_municipality.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class RegistrationStarted extends AuthEvent {
  const RegistrationStarted();
}

final class LoginEmailChanged extends AuthEvent {
  const LoginEmailChanged(this.value);
  final String value;
}

final class LoginPasswordChanged extends AuthEvent {
  const LoginPasswordChanged(this.value);
  final String value;
}

final class LoginSubmitted extends AuthEvent {
  const LoginSubmitted();
}

final class FullNameChanged extends AuthEvent {
  const FullNameChanged(this.value);
  final String value;
}

final class EmailChanged extends AuthEvent {
  const EmailChanged(this.value);
  final String value;
}

final class PhoneChanged extends AuthEvent {
  const PhoneChanged(this.value);
  final String value;
}

final class PasswordChanged extends AuthEvent {
  const PasswordChanged(this.value);
  final String value;
}

final class PasswordConfirmationChanged extends AuthEvent {
  const PasswordConfirmationChanged(this.value);
  final String value;
}

final class BusinessNameChanged extends AuthEvent {
  const BusinessNameChanged(this.value);
  final String value;
}

final class VatNumberChanged extends AuthEvent {
  const VatNumberChanged(this.value);
  final String value;
}

final class StreetAddressChanged extends AuthEvent {
  const StreetAddressChanged(this.value);
  final String value;
}

final class PostalCodeChanged extends AuthEvent {
  const PostalCodeChanged(this.value);
  final String value;
}

final class MunicipalityChanged extends AuthEvent {
  const MunicipalityChanged(this.value);
  final ItalianMunicipality? value;
}

final class RegistrationContinuePressed extends AuthEvent {
  const RegistrationContinuePressed();
}

final class RegistrationBackPressed extends AuthEvent {
  const RegistrationBackPressed();
}

final class EmailConfirmationPressed extends AuthEvent {
  const EmailConfirmationPressed();
}

final class AuthDialogDismissed extends AuthEvent {
  const AuthDialogDismissed();
}
